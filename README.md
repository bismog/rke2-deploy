虽然rke2安装已经很简化了，但是架不住节点多(如果节点不多，没必要考虑)，所以，还是有ansible批量化的需求。
如下这些是在rke2基础上的ansible部署的实现:
- https://github.com/rancherfederal/rke2-ansible
- https://github.com/lablabs/ansible-role-rke2

除了rke2本身，还增加了一些定制，比如如下组件的安装:
- rancher
- harbor
- longhorn
- gpu-operator
- ...
