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

// 解析hosts文件
const parseHostsFile = (content) => {
  const lines = content.split('\n');
  const config = { masters: [], workers: [] };
  let currentSection = null;

  lines.forEach((line) => {
    line = line.trim();
    if (line.startsWith('[masters]')) {
      currentSection = 'masters';
    } else if (line.startsWith('[workers]')) {
      currentSection = 'workers';
    } else if (line.startsWith('[')) {
      currentSection = null;
    } else if (currentSection && line) {
      const [name, ...params] = line.split(' ');
      const ip = params.find(param => param.startsWith('ansible_host')).split('=')[1];
      const type = params.find(param => param.startsWith('rke2_type')).split('=')[1];
      config[currentSection].push({ name, ip, type });
    }
  });

  return config;
};

// 读取hosts文件
app.get('/api/hosts', (req, res) => {
  const hostsPath = path.join(__dirname, '../hosts');
  // console.log('Hosts path:', hostsPath);

  try {
    const fileContents = fs.readFileSync(hostsPath, 'utf8');
    const config = parseHostsFile(fileContents);
    // console.log('当前hosts配置:', config);
    res.json(config);
  } catch (e) {
    console.error('读取hosts文件失败:', e);
    res.status(500).json({ error: '读取hosts文件失败' });
  }
});

// 更新hosts文件
function updateHosts(hosts) {
  const masters = hosts.filter(node => node.type === 'server');
  const workers = hosts.filter(node => node.type === 'agent');

  const hostsPath = path.join(__dirname, '../hosts');
  // console.log('Hosts path:', hostsPath);

  let hostsContent = '[masters]\n';
  masters.forEach(({ name, ip }) => {
    hostsContent += `${name} ansible_host=${ip} rke2_type=server\n`;
  });

  hostsContent += '\n[workers]\n';
  workers.forEach(({ name, ip }) => {
    hostsContent += `${name} ansible_host=${ip} rke2_type=agent\n`;
  });

  hostsContent += '\n[k8s_cluster:children]\nmasters\nworkers\n';

  try {
    fs.writeFileSync(hostsPath, hostsContent, 'utf8');
    console.log('更新hosts成功');
    return { success: true, message: '更新hosts成功' };
  } catch (e) {
    console.error('更新hosts失败:', e);
    return { success: false, message: '更新hosts失败' };
  }
}

// 读取group_vars/all.yml文件
app.get('/api/config', (req, res) => {
  const configPath = path.join(__dirname, '../group_vars/all.yml');
  // console.log('Config path:', configPath);

  try {
    const fileContents = fs.readFileSync(configPath, 'utf8');
    const config = yaml.load(fileContents);
    // console.log('当前配置:', config);
    res.json(config);
  } catch (e) {
    console.error('读取all.yml失败:', e);
    res.status(500).json({ error: '读取all.yml失败' });
  }
});

  // 更新group_vars/all.yml文件
function updateConfig(config) {
  const configPath = path.join(__dirname, '../group_vars/all.yml');  // 请根据实际路径修改

  try {
    const fileContents = fs.readFileSync(configPath, 'utf8');
    baseConfig = yaml.load(fileContents);
    // console.log('读取all.yml成功');
  } catch (e) {
    console.log('读取all.yml失败');
    return { success: false, message: '读取all.yml失败' };
  }

  const originalConfig = { ...baseConfig };

  // 更新配置项
  for (const key in config) {
    if (baseConfig.hasOwnProperty(key)) {
      baseConfig[key] = config[key];
    }
  }

  if (!deepEqual(originalConfig, baseConfig)) {
    try {
      const newYaml = yaml.dump(baseConfig, {
        'quotingType': "'",
        'forceQuotes': true,
      });
      fs.writeFileSync(configPath, newYaml, 'utf8');
      console.log('更新all.yml成功');
      return { success: true, message: '更新all.yml成功' };
    } catch (e) {
      console.log('更新all.yml失败');
      return { success: false, message: '更新all.yml失败' };
    }
  }
  else {
    console.log('all.yml无需更新');
    return { success: true, message: 'all.yml无需更新' };
  }
}

// 开始部署
app.post('/api/deploy', (req, res) => {
  const {
    hosts,
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

  const hostsResp = updateHosts(hosts);

  const configResp = updateConfig({
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
  });

  if (!(hostsResp.success && configResp.success)) {
    return res.status(500).json({
      message: 'Failed to update configuration',
      hostsMessage: hostsResp.message,
      configMessage: configResp.message
    });
  }

  // 执行install.sh脚本
  exec(path.join(__dirname, '../install.sh'), (error, stdout, stderr) => { 
    if (error) {
      console.error(`exec error: ${error}`);
      return res.status(500).json({ error: '安装脚本执行失败' });
    }
    console.log('开始部署...');
    // console.log(`stdout: ${stdout}`);
    // console.error(`stderr: ${stderr}`);
    res.status(200).json({ message: '部署开始' });
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Server is running on http://0.0.0.0:${PORT}`);
});
