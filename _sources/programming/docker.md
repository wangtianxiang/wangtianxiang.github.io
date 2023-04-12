# 快速搭建Docker容器开发环境
## 目的
平时经常需要在一个主机上开启多个docker容器，但容器与容器，容器与主机之间拷贝文件非常不方便，并且经常因为权限问题导致文件不可读写，或者因为使用root造成风险。所以编写一个脚本快速的创建docker容器，与Host，其他容器保持相同的目录结构，权限。并且支持设置映射端口号到容器22端口，设置容器root以及和主机相同用户名的账号密码。

共享下面2个目录

Host | Contanier | Note
---------|----------|---------
`${HOME}/work` | `${HOME}/work` | 共享工作目录
`${HOME}/.ssh` | `${HOME}/.ssh` | 方便ssh,git操作

```{note}
- 不建议直接共享`${HOME}`，会导致vscode无法同时attach 2个docker 容器。
- 安装[**Dev Containers**](https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials)插件后，第一次attach容器时，会自动拷贝local `.gitconfig`文件到容器内。
```

## 使用
````{div} full-width
```{eval-rst}
.. dropdown::
    :download:`Download script: docker_dev_env.sh <scripts/docker_dev_env.sh>`

    .. literalinclude:: scripts/docker_dev_env.sh
        :language: shell
```
````

### 快速使用
```shell
./docker_dev_env.sh -cs -i image_name -n container_name -p port
```
执行后会要求用户输入容器root,和host相同用户名账号的密码。若不需要设置密码，直接回车即可。

脚本主要分为两部分，一部分用来创建容器，一部分用来配置容器。

### 参数
**-c**

创建docker 容器。可以和 **-s** 一起使用。

-----------------

**-s**

配置docker 容器。可以和 **-c** 一起使用。

-----------------

**-i image_name**

使用的docker镜像名称，包括版本。若执行时不适用该参数，会在执行时要求用户输入。在只配置容器的时候，不需要该参数。

-----------------

**-n container_name**

创建的容器的名称。若执行时不适用该参数，会在执行时要求用户输入。注意名称最好只包含"字母，数字，-",由于脚本内同时设置了`--hostname`,否则使用mpirun 时会提示hostname不合法。如果不小心包含了其他字符，设置`export OMPI_MCA_regx=naive` 可以解决。

-----------------

**-p port**

将host的port映射到容器22端口。若执行时不适用该参数，会在执行时要求用户输入。

-----------------

```{note}
在`if [ $setup_container == "1" ]`分支下增加需要配置的内容。
```

## VScode 
[**Attach to a running container**](https://code.visualstudio.com/docs/devcontainers/attach-container)

1. 安装Docker, Dev Containers插件。
2. 按F1键 输入 Dev Containers: Attach to Running Container 选择之前创建的容器。
此时以默认方式进入容器，接下来修改以其他用户名进入。
3. 按F1键 输入 Dev Containers: Open Named Configuration File 打开一个json文件，根据需要修改该json文件。
```json
{
  // Default path to open when attaching to a new container.
  "workspaceFolder": "/path/to/code/in/container/here",

  // Set *default* container specific settings.json values on container create.
  "settings": {
    "terminal.integrated.defaultProfile.linux": "bash"
  },

  // Add the IDs of extensions you want installed when the container is created.
  "extensions": [],

  // An array port numbers to forward
  "forwardPorts": [],

  // Container user VS Code should use when connecting
  "remoteUser": "vscode",

  // Set environment variables for VS Code and sub-processes
  "remoteEnv": { "MY_VARIABLE": "some-value" }
}
```