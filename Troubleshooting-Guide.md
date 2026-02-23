# Native Kubernetes Troubleshooting Guide
# TravelMemory Application

This document outlines the step-by-step troubleshooting process we went through to get your native Kubernetes cluster (`kubeadm`) running successfully on your machine.

---

## Issue 1: `kubectl` Getting "Connection Refused"
**The Error Message:** 
```text
error: error validating "./k8s/mongo-deployment.yml": error validating data: failed to download openapi: Get "https://192.168.64.5:6443/openapi/v2?timeout=32s": dial tcp 192.168.64.5:6443: connect: connection refused
```
AND when running `kubectl get nodes`:
```text
The connection to the server 192.168.64.5:6443 was refused - did you specify the right host or port?
```

**The Investigation:**
We checked the status of the `kubelet` service (the core engine of a Kubernetes node) using `systemctl status kubelet`. It showed that the service was crashing repeatedly (`status=1/FAILURE`). We then looked at its detailed logs using `sudo journalctl -u kubelet -n 50 --no-pager` and found the culprit: 
```text
failed to run Kubelet: running with swap on is not supported, please disable swap! or set --fail-swap-on flag to false. /proc/swaps contained: /swap.img
```

**The Explanation:**
By default, native Kubernetes strictly refuses to run if your computer has "Swap Memory" turned on. Swap memory is when your computer uses its hard drive as extra RAM. Kubernetes hates this because it makes it impossible to accurately control how much real, fast RAM each container is allowed to use. 

**The Fix:**
1. We tried to temporarily disable swap memory using `sudo swapoff -a`.
2. However, your computer's RAM was so full that moving data out of swap space caused the `swapoff` command to be `Killed` by the system before it could finish.
3. Because we couldn't easily turn off swap, we instead configured the `kubelet` to completely ignore it. We edited the configuration file at `sudo nano /var/lib/kubelet/config.yaml` and added `failSwapOn: false` at the bottom of the file. 
4. We restarted the service (`sudo systemctl restart kubelet`), and the cluster came back to life immediately!

---

## Issue 2: Backend Pods Stuck in "Pending" State
**The Error Message:**
After the cluster was back online, we applied the backend deployment, but running `kubectl get pods` showed the backend pods sitting in a `Pending` state forever. We ran `kubectl describe pod backend-64764c955-4bw8r` to see why, and saw this warning:
```text
Warning  FailedScheduling  4m    default-scheduler  0/1 nodes are available: 1 node(s) had untolerated taint {node-role.kubernetes.io/control-plane: }. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
```

**The Explanation:**
In a production environment, you have multiple server machines. One acts as the "Master/Control-Plane" (which orchestrates things), and the others act as "Workers" (which actually run your application code). By default, Kubernetes puts a special invisible label called a "Taint" on the Master node that says, "Do not run any application code on me, I am too important."
Since you are only using one single computer for everything, your only node is the Master node. Because of the taint, Kubernetes refused to put your backend pods on it, leaving them homeless (`Pending`).

**The Fix:**
We manually removed that protective taint from your native single node using this command:
```bash
kubectl taint nodes --all node-role.kubernetes.io/control-plane-
```
As soon as the taint was removed, Kubernetes immediately scheduled and ran your backend pods.

---

## Issue 3: Database Storage Stuck in "Pending" State
**The Error Message:**
The MongoDB pod wouldn't start because its `PersistentVolumeClaim` (PVC) was stuck in a `Pending` state. We ran `kubectl describe pvc mongo-pvc` and found this error:
```text
Normal  FailedBinding  116s  persistentvolume-controller  no persistent volumes available for this claim and no storage class is set
```

**The Explanation:**
When you ask Kubernetes for a chunk of permanent hard drive space for a database, it relies on a robot helper called a "StorageClass" (or Storage Provisioner) to actually go and carve out that space on the physical hard drive.
Cloud providers like AWS, or tools like Minikube, install this robot helper automatically. A raw, native `kubeadm` cluster does not. So, your database was asking for storage, but nobody was there to fulfill the request.

**The Fix:**
1. We installed a popular helper called the `local-path-provisioner`. It automatically creates storage folders on your local hard drive whenever a database asks for it.
   ```bash
   kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
   ```
2. We then marked it as the "default" StorageClass for the entire cluster using a `kubectl patch` command:
   ```bash
   kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
   ```
3. We deleted the stuck MongoDB deployment/PVC with `kubectl delete -f mongo-deployment.yml`, and re-applied them. The new PVC instantly talked to the new default Storage Provisioner, got its storage allocated, and MongoDB transitioned to a `Running` state!
