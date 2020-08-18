# DEPLOYING OPENSHIFT CONTAINER STORAGE ON OPENSHIFT CONTAINER PLATFORM

The deployment process consists of 3 main parts

1. Install the OpenShift Container Storage Operator
2. Install the OpenShift Local Storage Operator
3. Create an OpenShift Container Storage service

### Installing Openshift Container Storage Operator

### Prerequisites
1. Log in to OpenShift Container Platform cluster.
2. You must have at least three worker nodes in the OpenShift Container Platform cluster.

### Procedure
* You must create a namespace called openshift-storage as follows
```
$ oc create -f ocs/ocs-ns.yaml
```
* Create a secret under openshift-marketplace namespace to access quay.io
```
$ oc create secret docker-registry -n openshift-marketplace olm-secret  --docker-server=quay.io/rhceph-dev --docker-username=<quay_username> --docker-password=<quay_password>
```
* Link above created olm-secret to all service accounts
```
$ oc get sa -n openshift-marketplace --no-headers | awk '{system("oc secrets link " $1 " olm-secret -n openshift-marketplace --for=pull")}'
```
* Create a custom catalog source for ocs operator
```
$ oc create -f ocs/ocs-catsrc.yaml
```
* Create a secret under openshift-storage namespace to access quay.io
```
$ oc create secret docker-registry -n openshift-storage ocs-secret  --docker-server=quay.io/rhceph-dev --docker-username=<quay_username> --docker-password=<quay_password>
```
* Now install OCS operator via UI or CLI

From UI: (Currently this is not available)

From the dash board, Navigate to Operators -> OperatorHub -> search for `OCS` -> from the search result click on OCS -> click on `install` -> choose `A specific namespace on the cluster` under installation mode and select `openshift-storage` as namespace -> choose `4.6-stable` under Update Channel -> click on `Subscribe`

From CLI:

```
$ oc apply -f ocs/ocs-operator.yaml
```
* Immediately execute below step to link ocs-secret to all service accounts
```
$ oc get sa -n openshift-storage  --no-headers | awk '{system("oc secrets link " $1 " ocs-secret -n openshift-storage --for=pull")}'
```
### Verfication
* To determine if OCS operator is deployed successfully, you can verify that the pods are in running state using below command.
```
$ oc get pods -n openshift-storage
````
Note: If you observe any errors in pods status, delete all the pods under openshift-storage namespace and check again.

Example:
```
[root@ocplnx31 z-ocs-auto]# oc get pods -n openshift-storage
noobaa-operator-549b677994-74mrz                                  1/1     Running            0          5m18s
ocs-operator-574c4c77dc-9dh89                                     1/1     Running            0          5m18s
rook-ceph-operator-85fcf94d75-5c7nn                               1/1     Running            0          5m18s
[root@ocplnx31 z-ocs-auto]#
```

## Installing Local Storage Operator

### Prerequisites:
1. You must have at least three OpenShift Container Platform worker nodes in the cluster with locally attached storage devices on each of them.
   * Each of the three worker nodes must have at least one raw block device available to be used by OpenShift Container Storage.
   * Minimum storage disk size with a capacity of 150GB.
You can use scripts in `lso` directory to setup extra disks for KVM or z/VM clusters accordingly.

ZVM:
```
$ sh lso/zvm-setup.sh <hostname of the worker node>
```
KVM:
```
$ sh lso/kvm-setup.sh
```
2. You must have a minimum of three labeled nodes.

   * Each worker node that has local storage devices to be used by OpenShift Container Storage must have a specific label to deploy OpenShift Container Storage pods. To label the nodes, use the following command:
```
$ oc label nodes <NodeName> cluster.ocs.openshift.io/openshift-storage=''
```
### Procedure
* Create local-storage namespace
```
$ oc create ns local-storage
```
* Now install Local Storage Operator via UI or CLI.

From UI:

From the dash board, Navigate to Operators -> OperatorHub -> search for `Local storage`-> from search result click on Local Storage  -> click on `install` -> choose `A specific namespace on the cluster` under installation mode and select `local-storage` as namespace -> choose `4.6` under Update Channel ->  click on `Subscribe`

From CLI:

```
$ oc apply -f lso/ls-operator.yaml
```

> For KVM cluster see [how-to](https://github.ibm.com/zdocker/howtos_public/wiki/How-to-install-Local-Storage-Operator-on-OCP-libvirt-cluster)

* You need to create 3 PVs after you installed Local Storage Operator.

There are 2 samples of PV yamls:

  lso/pvs-all-ine-one.yaml - if you have same config for all 3 workers and disks

  lso/pvs-separate.yaml - if you have different config

You need to replace `devicePaths` and `values` in nodeSelector according to your cluter
```
$ oc create -f lso/pvs-all-ine-one.yaml
```
### Verification
To determine if local storage operator is deployed successfully, you can verify that the pods are in running state using below command.
```
$ oc get pods -n local-storage
```
Example (3 worker nodes):
```
[root@ocplnx31 z-ocs-auto]# oc get pods -n local-storage
NAME                                      READY   STATUS    RESTARTS   AGE
local-disks-local-diskmaker-84hst         1/1     Running   0          3m12s
local-disks-local-diskmaker-86hqr         1/1     Running   0          3m12s
local-disks-local-diskmaker-hc2x7         1/1     Running   0          3m12s
local-disks-local-provisioner-b9566       1/1     Running   0          3m12s
local-disks-local-provisioner-pdmkm       1/1     Running   0          3m12s
local-disks-local-provisioner-wk6tn       1/1     Running   0          3m12s
local-storage-operator-6c44644f77-fht9d   1/1     Running   0          3m12s
[root@ocplnx31 z-ocs-auto]#
```

## Creating an OpenShift Container Storage service
* You need to create a new OpenShift Container Storage service after you install OpenShift Container Storage operator.

### Prerequisites
1. OpenShift Container Storage operator must be installed from the Operator Hub

### Procedure
There are 2 StorageCluster in storage-cluster directory
* storage-cluster-mixed.yaml - StorageCluster YAML with placement override and mixed disk sizes
* storage-cluster.yaml - StorageCluster YAML without placement override (Can be used when all the storage nodes are similar and have same number of disk of same same size)
```
$ oc create -f storage-cluster/storage-cluster-mixed.yaml
```
### Verification
* To determine if storage cluster is deployed successfully, you can verify that the pods are in running state using below command.
```
$ oc get pods -n openshift-storage
```
Example(3 woker nodes):
```
[root@ocplnx31 z-ocs-auto]# oc get pods -n openshift-storage
NAME                                                              READY   STATUS             RESTARTS   AGE
csi-cephfsplugin-7cph9                                            3/3     Running            0          5m43s
csi-cephfsplugin-hjx8n                                            3/3     Running            0          5m43s
csi-cephfsplugin-jhlqq                                            3/3     Running            0          5m43s
csi-cephfsplugin-m6lwb                                            3/3     Running            0          5m43s
csi-cephfsplugin-provisioner-6b5447476f-86hvm                     5/5     Running            0          5m43s
csi-cephfsplugin-provisioner-6b5447476f-w4hd7                     5/5     Running            0          5m43s
csi-cephfsplugin-srfv5                                            3/3     Running            0          5m43s
csi-cephfsplugin-tht7s                                            3/3     Running            0          5m43s
csi-cephfsplugin-zt5s9                                            3/3     Running            0          5m43s
csi-rbdplugin-59zm2                                               3/3     Running            0          5m43s
csi-rbdplugin-d4npb                                               3/3     Running            0          5m43s
csi-rbdplugin-dd5bm                                               3/3     Running            0          5m43s
csi-rbdplugin-fnngw                                               3/3     Running            0          5m43s
csi-rbdplugin-m2jmd                                               3/3     Running            0          5m43s
csi-rbdplugin-m5fsb                                               3/3     Running            0          5m43s
csi-rbdplugin-provisioner-7d99f47b68-b4kl4                        5/5     Running            0          5m43s
csi-rbdplugin-provisioner-7d99f47b68-gq2qw                        5/5     Running            0          5m43s
csi-rbdplugin-vbzgw                                               3/3     Running            0          5m43s
noobaa-core-0                                                     1/1     Running            0          2m37s
noobaa-db-0                                                       1/1     Running            0          2m37s
noobaa-endpoint-5b7d5fcf94-qwln8                                  1/1     Running            0          81s
noobaa-operator-549b677994-vxh9t                                  1/1     Running            0          9m58s
ocs-operator-574c4c77dc-2z7qh                                     1/1     Running            0          9m58s
rook-ceph-crashcollector-worker-0.cluster4.ibm.com-6968b7dbglcq   1/1     Running            0          3m48s
rook-ceph-crashcollector-worker-1.cluster4.ibm.com-6c59cc8q57jf   1/1     Running            0          4m6s
rook-ceph-crashcollector-worker-2.cluster4.ibm.com-8f7bb8bcfsfh   1/1     Running            0          4m23s
rook-ceph-crashcollector-worker-3.cluster6.ibm.com-8fd484ctnv4z   1/1     Running            0          4m51s
rook-ceph-drain-canary-worker-0.cluster4.ibm.com-54c8bd46flhm2v   1/1     Running            0          2m42s
rook-ceph-drain-canary-worker-1.cluster4.ibm.com-7796ffbb7svzqx   1/1     Running            0          2m41s
rook-ceph-drain-canary-worker-2.cluster4.ibm.com-95fb77ffbf4f6z   1/1     Running            0          2m40s
rook-ceph-drain-canary-worker-3.cluster6.ibm.com-5949944ffsxn4z   1/1     Running 	     0          2m43s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-a-864c66fbd5qww   1/1     Running            0          2m13s
rook-ceph-mds-ocs-storagecluster-cephfilesystem-b-55bccc7455xbx   1/1     Running            0          2m12s
rook-ceph-mgr-a-85f8947b76-wc98f                                  1/1     Running            0          3m22s
rook-ceph-mon-a-5fd755454c-9bbsj                                  1/1     Running            0          4m23s
rook-ceph-mon-b-67d5f957f5-vv699                                  1/1     Running            0          4m6s
rook-ceph-mon-c-5d9f74cd65-bv5s4                                  1/1     Running            0          3m48s
rook-ceph-operator-85fcf94d75-762jt                               1/1     Running            0          9m58s
rook-ceph-osd-0-758dc8bb9b-54b4k                                  1/1     Running            0          2m42s
rook-ceph-osd-1-57bdc87c7c-rhcg8                                  1/1     Running            0          2m41s
rook-ceph-osd-2-5dd7479cd9-d2n6m                                  1/1     Running            0          2m40s
rook-ceph-osd-prepare-ocs-deviceset-0-0-g49tv-8mmbh               0/1     Completed          0          3m1s
rook-ceph-osd-prepare-ocs-deviceset-1-0-8xbmf-grph5               0/1     Completed          0          3m
rook-ceph-osd-prepare-ocs-deviceset-2-0-jhh5b-2h8pj               0/1     Completed          0          3m
rook-ceph-rgw-ocs-storagecluster-cephobjectstore-a-5c4c77dcwckq   1/1     Running            0          99s
rook-ceph-rgw-ocs-storagecluster-cephobjectstore-b-95cdd8874d7w   1/1     Running	     0          99s
[root@ocplnx31 z-ocs-auto]# oc get pods -n openshift-storage|wc -l
46
```
## Verifying OpenShift Container Storage deployment
* To determine if OpenShift Container Storage is deployed successfully, you can verify by deploying sample pod as follows.

   In samples directory you can find yaml files to create PVC and start pod using this PVC with ocs-storagecluster-cephfs storage class create by StorageCluster
```
$ oc create -f samples/sample-pod.yaml
```
