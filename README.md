=========================================================== Terraform ======================================================================================

These eks cluster consists deployed nodes in the private subnets with access to the internet through the nat gateway provisioned in the public sunbets. 3 private subnets along with 3 public subnet in 3 different availabilty zones are provisioned in a unique eks_vpc. Each private subnets has 2nodes with minimum of 2 EC2 instance within the cluster for deployment of the pods. An illustration of the architecture is on .png file

Create or update the kubeconfig for Amazon EKS. run "aws eks update-kubeconfig --region <region-code> --name <cluster-name>"

Replace <region-code> with you respective region, and <cluster-name> with your cluster name

============================================================ Kubernetes ===============================================================================================

To test this infrastructure, run "kubectl apply -f " in the path where kubernetes files to deploy a simple application in the private subnet is saved and test. Link to simple kubernete code the test a voting app can be found there  https://github.com/zeandemi/votingAppKub_File 