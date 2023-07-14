# Dockerfile for building your application.
# Defines the final image that contains content from both the image and template.
# Step 1 build the application
FROM golang:1.17.0 as buildEnv
# Get the source code of application
COPY . /project/src/myservice
# Set env variable fo GO environment
ENV GOPATH=/project
# ensure all the dependencies are present
WORKDIR /project/src/myservice
RUN go mod tidy
# build the executable application
#WORKDIR /project
#RUN ls -al /project
RUN go build -o /userapp
# ensure execution priviledges for application
RUN chmod +x /userapp

# Step 2 build the final image
# use 
FROM registry.access.redhat.com/ubi8/ubi:8.8-1009
ARG UID=65000
ARG GID=65000
WORKDIR /
RUN yum install shadow-utils.x86_64 -y
RUN yum install sudo.x86_64 -y
# get the application from the build container (buildEnv)
# COPY --from=buildEnv /userapp ./
RUN groupadd --g 65000 nonroot
RUN useradd -u 65000 -g 65000 nonroot
RUN echo 'nonroot ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers
USER nonroot
RUN sudo mkdir -p /var/app
RUN sudo chmod 777 /var/app
# get the application from the build container (buildEnv)
COPY --from=buildEnv --chown=nonroot:nonroot /userapp ./
# expose the port used
ENV PORT=8080
EXPOSE ${PORT}
#define label
LABEL "version"="1.0.0" \
      "maintainer"="jerome.tarte@fr.ibm.com" \
      "description"="provide a sample application written in GO lang"
# Pass control your application
CMD ["/userapp"]
