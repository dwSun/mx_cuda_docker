# 起因

最近看mxnet的东西，打算给实验室的机器装一个mxnet的环境，无奈实验室里面机器已经装了tensorflow，运行了好久了，环境比较老。而mxnet可是支持最新的cuda9和cudnn7的。研究了一段时间后，发现cuda的docker镜像是个不错的选择。别问我为啥不编译tensorflow以获得cuda9和cudnn7的支持，谁再让我编译tensorflow，谁是XX。


试着装了一个cuda9的docker镜像，发现很好用，基本除了nvidia-docker之外，不需要其他任何外部依赖。


配合atom的插件hydrogen，可以实现notebook的几乎全部功能。


# docker的安装

参考 https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/
docker的手册写的很好，没啥好说的

# nvidia-docker2的安装

nvidia-docker有一版本的安装，也有2版本，这里推荐2版本，虽然还在开发，不适合production。不过实验室里面跑跑还考虑啥。
安装参考 https://github.com/NVIDIA/nvidia-docker/tree/2.0

需要注意一点的是，nvidia-docker2安装之后，需要设置一下：
参考 https://github.com/nvidia/nvidia-container-runtime#installation

# 镜像的选择

nvidia自己以ubuntu16.04的镜像为基础创建了一堆cuda的镜像：
https://hub.docker.com/r/nvidia/cuda/

这些镜像中包含不同的cuda版本，以及不同的cuda库配置。
这里选用 **9.0-cudnn7-runtime** 这个标签的镜像作为基础。

# 构建docker镜像
这里使用的是**docker build**命令配合**Dockerfile**文件。

**Dockerfile**的语法参考 https://docs.docker.com/engine/reference/builder/
## Dockerfile

文件内容如下
```yml
FROM nvidia/cuda:9.0-cudnn7-runtime
MAINTAINER dwSun

ADD sources.list /etc/apt/sources.list
RUN apt-get update
RUN apt-get install python3-pip libgfortran3 -y
RUN pip3 install mxnet-cu90mkl jupyter matplotlib pandas ipython scikit-image -i https://pypi.douban.com/simple/ && rm -rvf ~/.cache

RUN jupyter notebook --generate-config
RUN sed "s/#c.NotebookApp.token = '<generated>'/c.NotebookApp.token = 'mx_cuda'/" /root/.jupyter/jupyter_notebook_config.py -i

RUN mkdir /code
WORKDIR /code

EXPOSE 8888
CMD jupyter notebook --port=8888 --ip 0.0.0.0 --no-browser --allow-root

```

文件中有对**sources.list**文件的引用，这个文件跟**Dockerfile**放在同一个目录下面。文件为国内阿里的ubuntu镜像源，为的是**apt-get**的时候能够快一点，文件内容如下：

```sh
deb http://mirrors.aliyun.com/ubuntu/ xenial main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-security main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-updates main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-proposed main restricted universe multiverse
deb http://mirrors.aliyun.com/ubuntu/ xenial-backports main restricted universe multiverse
```
也可以使用其他的国内linux源，具体细节参考各个linux源关于ubuntu的使用说明。

docker内的文件需要使用volume传递给外界，所以这里的镜像预留了一个**code**目录作为运行目录，使用默认参数运行的话，会直接从**code**目录启动ipython kernel的gateway。

**sed**前后的两行是为了让**hydrogen**运行的时候，可以不用输入**token**，这里直接将**token**设置为了**mx_cuda**
更详细的内容，参考 https://nteract.gitbooks.io/hydrogen/docs/Usage/RemoteKernelConnection.html

## build
到**Dockerfile**所在的文件夹下面执行
```sh
docker build . -t mx_cuda
```

这里生成一个tag为**mx_cuda**的镜像。
需要注意的是，**Dockerfile**所在的文件会被整个发送给docker dameon作为编译的context，所以不要在这个文件夹里放其他没有意义的东西，更不要使用**home**目录。

# hydrogen

## 介绍
参考：https://atom.io/packages/hydrogen

他们还有一个叫做**nteract**的项目，是桌面版本的notebook。参考 https://github.com/nteract/nteract

## 安装
使用apm或者直接在atom里面安装 **hydrogen**

```sh
apm install hydrogen
```

## 设置

找到hydrogen的设置，在 Kernel Gateways里面填写：
```json
[
  {
    "name": "your config name",
    "options": {
      "baseUrl": "http://your_cuda_host_ip:port",
      "token": "mx_cuda"
    }
  }
]
```


# 运行
到cuda的主机里面执行以下命令，启动docker镜像里面的ipython kernel gateway。
```sh
docker run --runtime=nvidia -p 0.0.0.0:8888:8888 --rm mx_cuda -d
or
docker run --runtime=nvidia -p 0.0.0.0:8888:8888 --rm -v path:/code mx_cuda -d
```

在atom里面编写一个简单的mxnet测试脚本，使用**ctrl+shift+p**找到**Hydrpgen： Connect to Remote Kernel**并运行

然后就是实际的使用了。



