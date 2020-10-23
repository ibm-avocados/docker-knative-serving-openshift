FROM registry.fedoraproject.org/fedora-minimal:latest
# Can configure oc and kubectl versions. Default is oc 4.4 with the matching kubectl version
# See https://cloud.ibm.com/docs/openshift?topic=openshift-openshift_versions#version_types
# for more info about Kubernetes version used with specific versions of OpenShift
# OpenShift 4.4 (Default)
ARG OPENSHIFT_VERSION=4.4
ARG KUBECTL_VERSION=1.17.13

# OpenShift 4.5 (Need to provide via --build-arg flags when building)
# docker build ... --build-arg OPENSHIFT_VERSION=4.5 --build-arg KUBECTL_VERSION=1.18.10 ...


# Need tar command
RUN microdnf install -y tar

# Install kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl && chmod +x ./kubectl && mv ./kubectl /usr/local/bin/kubectl

# Install  ibmcloud cli with  openshift plugin
RUN curl -fsSL https://clis.cloud.ibm.com/install/linux | sh
RUN ibmcloud plugin install container-service

# Install oc
RUN curl -LO  https://mirror.openshift.com/pub/openshift-v4/clients/oc/${OPENSHIFT_VERSION}/linux/oc.tar.gz && tar -zxf oc.tar.gz
RUN  mv ./oc /usr/local/bin/oc && rm oc.tar.gz

# Create a scripts dir for child images to put their scripts
RUN mkdir /scripts

WORKDIR /scripts

# Child scripts will copy their unique scripts to the /scripts folder
COPY scripts/* /scripts/
RUN chmod +x /scripts/*.sh
