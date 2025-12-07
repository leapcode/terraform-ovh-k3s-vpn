# Provision a single- or multi-node cluster on OVH

## 1. Create a Public cloud project on OVH
Register on OVH and create a Public Cloud project.
Please note: by default OVH enforces quite strict quota and often you are only allowed to provision resources in the region you chose for your cloud project. You can check the quotas and the regional codes of your public cloud project for each region in the OVH cloud dashboard under **Public Cloud / Settings / Quota & Regions**.

## 2. Configure your project

Whether you want to provision a single-node cluster to use it as a gateway or a multi-node cluster for backend services, it's easiest to start with the template files under **ovh/examples**. Here you find the code to import this repo as a git module and all the variables you need to provide. Just copy the template file to a directory you wish and adapt it.

### a) Ensure git access
Make sure you have access to the git repo and can git clone it, otherwise terraform init will fail.\
Alternatively you can use the ssh-method to clone the repo during the init-process by replacing the source = ...  line by source = "git::ssh://git@0xacab.org/leap/container-platform/terraform-k3s.git//ovh?ref=no-masters"

### b) Provide important variables
Here is a list of the variables you'll need to provide:
| Variable | Type | Description |
| --------- | ---- | --------- |
| *ovh_service_name* | string | the id of your public cloud project. You find it in the OVH console under your project name. | 
| *ovh_region* | string | the OVH regional code for the region you want to provision resources in. Please mind your quota. |
| *admin_ssh_key* | object({ name = string, public_key = string }) | An object containing any chosen name as *name* and your public ssh-key as *public_key*. A ssh_key resource will be created and linked to all of your created instances.

And these are variables you should use to configure your cluster:
| Variable | Type | Description |
| --------- | ---- | --------- |
| *additional_ssh_keys* | list[string] | A list of additional public ssh-keys as strings that you want to grant access to your resources to. Defaults to []. |
| *k3s_cluster_name* | string | The name for your k3s cluster. Defaults to "k3s-leap". |
| *k3s_leader_count* | number | The number of leader nodes. Must be odd. Right now, multi-leader is not yet implemented, so only 1 will be accepted. |
| *k3s_controller_server_type* | string | The OVH flavor name for controller nodes. Choose one from https://www.ovhcloud.com/de/public-cloud/prices/#552. Defaults to "b2-7" |
| *k3s_base_os* | string | The name of the operating system (image name) to install on all controller nodes and the default for worker nodes. Defaults to "Debian 13". |
| *gateway_mode_enabled* |boolean | Set to true if you want to provision a gateway, false else. Defaults to false. |
| *k3s_network_name* | string | Name for the network. Defaults to "k3s-leap". |
| *k3s_worker_nodes* |list(object({ name = string, count = number, server_type = string, image_name = optional(string)  })) | A list of groups of worker nodes, each sharing a common operating system and server flavor. The variable *count* determines how many nodes of this kind you want to spin up. The *image_name* defaults to the value of *k3s_base_os*. In a single-node cluster like a gateway this variable should be [] as there is only one controller node and no worker nodes. Defaults to []. |

## 3. Create OVH secrets
Next step is to create the OVH application key, application secret and consumer key. All of these are neccessary so that your terraform code is allowed to make requests to the OVH API. You can create them here:

https://www.ovh.com/auth/api/createToken

For 'Application name' and 'Application description' you can use whatever you like. For the sake of this tutorial it is easiest to manually add one line for each right (GET, PUT, POST, DELETE) and put * in the field to the right, thus granting your application universal rights. If you wish to have more control, you can play around here.

Next we have to somehow give these secrets to terraform, so it can use them when making API calls to OVH. There are multiple ways to handle secret variables like these, but for now we will do it via environment variables following the scheme:\
`export OVH_<variable_name>=<value>` .

Open a shell and set all of the created secrets by typing the following commands:

```
export OVH_CONSUMER_KEY=<your_consumer_key>
export OVH_APPLICATION_SECRET=<your_application_secret>
export OVH_APPLICATION_KEY=<your_application_key>
```

Additionally you should set your endpoint to your specific region. For the EU you set:
```
export OVH_ENDPOINT=ovh-eu
```

## 4. Provision the resources

### a) Initialize terraform
In the same shell and in the folder with your terraform project file, run 
```
terraform init
``` 

When everything works out run 
```
terraform plan
```
Read the plan and make sure things are getting created as expected.

Last run 
```
terraform apply
```
Your k3s cluster is now being provisioned. 🎊\
You can check on the OVH dashboard if all of your resources are created as expected.

## 5. Accessing the cluster using port forwarding

This method allows provisioning from your local machine to remotes.
If not done before, copy the directory `terraform-k3s/ovh/examples/scripts` to your working directory and run within the working directory:
```bash
eval $(./scripts/access_cluster.sh --start)
```
Calling this script like described above will pull the k3s.yml from your controller node, adapt it for use on localhost, create in a background process a ssh tunnel with port forwarding on port 6443 to your controller node and automatically export the `KUBECONFIG` environment variable to your current shell. 

If you have provisioned your cluster with a different SSH key than your default one, you can amend `--ssh-key <path/to/your/ssh-key` to the command:

```bash
eval $(./scripts/portforwarding.sh --start --ssh-key <path/to/your/ssh-key>)
```

Test the kubectl commands using the following command (if you haven’t yet installed kubectl on your local machine, follow this guide: https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/). This should return a table with your deployed nodes.

```bash
kubectl get nodes -o wide
```

If you want to run kubectl in a different shell then the one you've used to start port forwarding just export there the KUBECONFIG:

```bash
export KUBECONFIG=<path-to-your-work-dir>/k3s-local.yaml
```

### Stopping port forwarding
Once you're done with your work, you should close your ssh session to your controller node and disable port forwarding again. This can be done by running

```bash
./scripts/portforwarding.sh --stop
```

### Some useful `kubectl` commands
#### list all nodes and wide output
```bash
kubectl get nodes -o wide
```

#### list all pods in all namespaces
```bash
kubectl get pods -A -o wide
```

