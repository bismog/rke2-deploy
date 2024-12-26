const express = require('express');
const bodyParser = require('body-parser');
const { exec } = require('child_process');
const fs = require('fs');
const path = require('path');
const yaml = require('js-yaml');
const deepEqual = require('fast-deep-equal');
const app = express();
const PORT = process.env.PORT || 12345;

app.use(bodyParser.json());

// 静态文件index.html
app.use(express.static(path.join(__dirname, '../')));

app.get('/api/config', (req, res) => {
  const configPath = path.join(__dirname, '../group_vars/all.yml');
  console.log('Config path:', configPath);

  try {
    const fileContents = fs.readFileSync(configPath, 'utf8');
    const config = yaml.load(fileContents);
    console.log('当前配置:', config);
    res.json(config);
  } catch (e) {
    console.error('读取YAML文件失败:', e);
    res.status(500).json({ error: '读取YAML文件失败' });
  }
});

app.post('/api/deploy', (req, res) => {
  const {
    enable_ha_mode,
    enable_rancher,
    rke2_server_hostname,
    enable_longhorn,
    enable_harbor,
    harbor_domain_name,
    enable_gpu_operator,
    enable_nfs_provisioner,
    nfs_server_ip,
    nfs_server_path,
    enable_multiple_networks,
    data_iface,
    data_network_name
  } = req.body;

  // if (!rke2_server_hostname) {
  //   return res.status(400).json({ error: 'rke2_server_hostname are required' });
  // }

  // 更新group_vars/all.yml文件
  const configPath = path.join(__dirname, '../group_vars/all.yml');  // 请根据实际路径修改

  let config;
  try {
    const fileContents = fs.readFileSync(configPath, 'utf8');
    config = yaml.load(fileContents);
  } catch (e) {
    return res.status(500).json({ error: '读取YAML文件失败' });
  }

  const originalConfig = { ...config };

  // 更新配置项
  config.enable_ha_mode = enable_ha_mode;
  config.enable_rancher = enable_rancher;
  config.enable_longhorn = enable_longhorn;
  config.enable_harbor = enable_harbor;
  config.enable_gpu_operator = enable_gpu_operator;
  config.enable_nfs_provisioner = enable_nfs_provisioner;
  config.enable_multiple_networks = enable_multiple_networks;
  if (enable_rancher === 'yes') {
    config.rke2_server_hostname = rke2_server_hostname;
  }
  if (enable_harbor === 'yes') {
    config.harbor_domain_name = harbor_domain_name;
  }
  if (enable_nfs_provisioner === 'yes') {
    config.nfs_server_ip = nfs_server_ip;
    config.nfs_server_path = nfs_server_path;
  }
  if (enable_multiple_networks === 'yes') {
    config.data_iface = data_iface;
    config.data_network_name = data_network_name;
  }

  if (!deepEqual(config, originalConfig)) {
    try {
      const newYaml = yaml.dump(config, {
        'quotingType': '"',
        'forceQuotes': true,
      });
      fs.writeFileSync(configPath, newYaml, 'utf8');
    } catch (e) {
      return res.status(500).json({ error: '写入YAML文件失败' });
    }
  }

  // 执行install.sh脚本
  exec(path.join(__dirname, '../install.sh'), (error, stdout, stderr) => { 
    if (error) {
      console.error(`exec error: ${error}`);
      return res.status(500).json({ error: '安装脚本执行失败' });
    }
    console.log(`stdout: ${stdout}`);
    // console.error(`stderr: ${stderr}`);
    res.status(200).json({ message: '部署开始' });
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
