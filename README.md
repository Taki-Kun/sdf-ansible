## 部署任务

> ansible-playbook 执行 Playbook 时默认并发为 5，部署目标机器较多时可添加 -f 参数指定并发，如 `ansible-playbook deploy.yml -f 10`

部署ansible虚拟环境，进入虚拟环境
```bash
git clone <Ansible RepoUrl>
mkdir -p /opt/ansible
cp ansible/requirements.txt /opt/ansible/requirements.txt
cd /opt/ansible
/usr/local/python2.7/bin/virtualenv env
source env/bin/activate
pip install -r requirements.txt
```
退出虚拟环境
```bash
deactivate
```

1.  ~~确认 `****-ansible/inventories/**/**inventory**.ini` 文件中 `ansible_user = mahjong`，本例使用 `mahjong` 用户作为服务运行用户，配置如下：~~

    ```ini
    ## Connection
    # ssh via normal user
    ansible_user = mahjong
    ```
 
    ~~执行以下命令如果所有 server 返回 `mahjong` 表示 ssh 互信配置成功。~~
    ```bash
    ansible-playbook -i inventories/**/hosts.ini all -m shell -a 'whoami'
    ```

    ~~执行以下命令如果所有 server 返回 `root` 表示 `mahjong` 用户 sudo 免密码配置成功。~~
    ```bash
    ansible-playbook -i inventories/**/hosts.ini all -m shell -a 'whoami' -b
    ```

    确认 `****-ansible/inventories/**/**inventory**.ini` 文件中 `ansible_user = root`，本例使用 `root` 用户作为服务运行用户

2.  配置`Jenkins`构建主机组`local_inventory_RC.ini`

    ```ini
    [jiangsu_region_game_servers]
    jiangsu_region_game ansible_host="127.0.0.1" directory="jiangsu_region_game" dirtype="game"
    jiangsu_region_router1 ansible_host="127.0.0.1" directory="jiangsu_region_router1" dirtype="router1"
    jiangsu_region_router2 ansible_host="127.0.0.1" directory="jiangsu_region_router2" dirtype="router2"

    [jiangsu_region_game_servers:vars]
    docker_network_subnet = "172.172.1.0/24"  # eg: "172.172.2.0/24" "172.172.3.0/24"
    docker_network_gateway = "172.172.1.1"  # eg: "172.172.2.1" "172.172.3.1"
    docker_network_iprange = "172.172.1.0/24"  # eg: "172.172.2.0/24" "172.172.3.0/24"
    use_zookeeper = "on"  # on/off
    ```

3.  配置`Jenkins`部署主机组`inventory_RC.ini`

    ```ini
    [jiangsu_region_game_servers]
    jiangsu_region_game ansible_host="192.168.8.171" directory="jiangsu_region_game" dirtype="game"
    jiangsu_region_router1 ansible_host="192.168.8.171" directory="jiangsu_region_router1" dirtype="router1"
    jiangsu_region_router2 ansible_host="192.168.8.171" directory="jiangsu_region_router2" dirtype="router2"

    [jiangsu_region_game_servers:vars]
    docker_network_subnet = "172.172.1.0/24"  # eg: "172.172.2.0/24" "172.172.3.0/24"
    docker_network_gateway = "172.172.1.1"  # eg: "172.172.2.1" "172.172.3.1"
    docker_network_iprange = "172.172.1.0/24"  # eg: "172.172.2.0/24" "172.172.3.0/24"
    use_zookeeper = "on"  # on/off
    stand_alone = "on"  # on/off 是否单宿主机
    ```

4.  检查 `inventories/**/**inventory**.ini`配置
    > `EDITION` 决定环境，影响vars加载机制，由`Jenkins`传入或手工传入。
    > `WORKSPACE` 决定工作目录，若作环境配置则传入`ansible`路径，若做部署更新则传入`jenkinsfile
    `路径
    > `game_version`作为版本控制的tag，暂时只作`Docker`镜像tag使用。

5.  部署`Docker`仓库证书及调用docker api的python虚拟环境

    ```bash
    ansible-playbook -i inventories/**/hosts_**.ini bootstrap.yml
    ```

5.  创建配置文件目录组
    > `GAME_HOST` 与业务项目名或`Jenkinsfile`分支名或主机配置文件内的主机组名一致

    ```bash
    ansible-playbook -i inventories/**/local_inventory_**.ini create_default_conf.yml -e 'WORKSPACE="/path/to/ansible"' -e 'GAME_HOST="<production Name>_servers"'  
    ```

6.  修改配置文件目录组内的配置

    ```bash
    vi <some yaml>
    ```

7.  本地构建

    ```bash
    ansible-playbook -i inventories/**/local_inventory_**.ini local_prepare.yml -e 'WORKSPACE="/path/to/Jenkinsfile"' -e 'GAME_HOST="<production Name>_servers"'
    ```

8.  远程部署

    ```bash
    ansible-playbook -i inventories/**/inventory_**.ini deploy.yml -e 'WORKSPACE="/path/to/Jenkinsfile"' -e 'GAME_HOST="<production Name>_servers"'
    ```

9.  `Jenkins`部署方式忽略 8、 9 步骤，触发`Jenkins`对应分支的job


### 如何配置 ssh 互信及 sudo 免密码

#### 在中控机上创建 mahjong 用户，并生成 ssh key。
```
# useradd mahjong
# passwd mahjong
# su - mahjong
$
$ ssh-keygen -t rsa
Generating public/private rsa key pair.
Enter file in which to save the key (/home/mahjong/.ssh/id_rsa):
Created directory '/home/mahjong/.ssh'.
Enter passphrase (empty for no passphrase):
Enter same passphrase again:
Your identification has been saved in /home/mahjong/.ssh/id_rsa.
Your public key has been saved in /home/mahjong/.ssh/id_rsa.pub.
The key fingerprint is:
SHA256:eIBykszR1KyECA/h0d7PRKz4fhAeli7IrVphhte7/So mahjong@192.168.8.171
The key's randomart image is:
+---[RSA 2048]----+
|=+o+.o.          |
|o=o+o.oo         |
| .O.=.=          |
| . B.B +         |
|o B * B S        |
| * + * +         |
|  o + .          |
| o  E+ .         |
|o   ..+o.        |
+----[SHA256]-----+
```

#### 如何使用 Ansible 自动配置 ssh 互信及 sudo 免密码

下载 ****-Ansible，将你的部署目标机器 IP 添加到 `[servers]` 区块下。

```
$ vi hosts.ini
[servers]
192.168.8.171
192.168.8.172
192.168.8.173
192.168.8.174

[all:vars]
username = mahjong
```

执行以下命令，按提示输入部署目标机器 root 密码。

```
$ ansible-playbook -i hosts.ini create_users.yml -k
```

#### 如何手工配置 ssh 互信及 sudo 免密码

以 `root` 用户依次登录到部署目标机器创建 `mahjong` 用户并设置登录密码。

```
# useradd mahjong
# passwd mahjong
```

执行以下命令，将 `mahjong ALL=(ALL) NOPASSWD: ALL` 添加到文件末尾，即配置好 sudo 免密码。

```
# visudo
mahjong ALL=(ALL) NOPASSWD: ALL
```

以 `mahjong` 用户登录到中控机，执行以下命令，将 `192.168.8.172` 替换成你的部署目标机器 IP，按提示输入部署目标机器 mahjong 用户密码，执行成功后即创建好 ssh 互信，其他机器同理。

```
[mahjong@192.168.8.171 ~]$ ssh-copy-id -i ~/.ssh/id_rsa.pub 192.168.8.172
```

#### 验证 ssh 互信及 sudo 免密码
以 `mahjong` 用户登录到中控机，ssh 登录目标机器 IP，不需要输入密码并登录成功，表示 ssh 互信配置成功。

```
[mahjong@192.168.8.171 ~]$ ssh 192.168.8.172
[mahjong@192.168.8.172 ~]$
```

以 `mahjong` 用户登录到部署目标机器后，执行以下命令，不需要输入密码并切换到 root 用户，表示 `mahjong` 用户 sudo 免密码配置成功。

```
[mahjong@192.168.8.172 ~]$ sudo -su root
[root@192.168.8.172 mahjong]#
```
