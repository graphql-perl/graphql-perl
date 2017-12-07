# from https://docs.docker.com/get-started/part2/#dockerfile
# stuff from https://hub.docker.com/_/perl/
# + https://github.com/perl/docker-perl/blob/master/5.026.001-64bit/Dockerfile
FROM graphqlperl/graphql-prereq:latest

# Copy the current directory contents into the container
ADD . /opt/graphql-lib/

RUN cd /opt/graphql-lib \
  && perl Makefile.PL \
  && make test install \
  && perl5.26.1 -MGraphQL -e0
