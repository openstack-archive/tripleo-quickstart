FROM centos
LABEL maintainer=rdoci
LABEL name=quickstart


COPY . /quickstart
WORKDIR /quickstart

RUN yum install -y sudo && ./quickstart.sh --install-deps

CMD ["/quickstart/quickstart.sh", "--no-clone", "--bootstrap", "${VIRTHOST}"]
