# prereqs builder

# from https://docs.docker.com/get-started/part2/#dockerfile
# stuff from https://hub.docker.com/_/perl/
# + https://github.com/perl/docker-perl/blob/master/5.026.001-64bit/Dockerfile
FROM perl:5.26.1

# Copy the current directory contents into the container
ADD . /opt/graphql-prereq/

# Install any needed packages - -v so can see errors
RUN cd /opt/graphql-prereq \
  && perl Makefile.PL \
  && cpanm -v --installdeps . \
  && true
