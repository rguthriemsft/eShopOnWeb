# RUN ALL CONTAINERS FROM ROOT (folder with .sln file):
# docker-compose build
# docker-compose up
#
# RUN JUST THIS CONTAINER FROM ROOT (folder with .sln file):
# docker build --pull -t web -f src/Web/Dockerfile .
#
# RUN COMMAND
#  docker run --name eshopweb --rm -it -p 5106:5106 web
FROM microsoft/dotnet:2.2-sdk AS build
WORKDIR /app

COPY src /app 
WORKDIR /app/Web
RUN dotnet restore

RUN dotnet publish -c Release -o out

FROM microsoft/dotnet:2.2-aspnetcore-runtime AS runtime
WORKDIR /app
COPY --from=build /app/Web/out .


RUN groupadd -r coreteam && useradd -r -s /bin/false -g coreteam coreteam

# Optional: Set this here if not setting it from docker-compose.yml
# ENV ASPNETCORE_ENVIRONMENT Development
RUN chown -R coreteam:coreteam /app
USER coreteam
EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080
ENTRYPOINT ["dotnet", "Web.dll", "--environment=development"]
