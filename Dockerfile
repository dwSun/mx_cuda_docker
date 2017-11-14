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
