# RUN ALL CONTAINERS FROM ROOT (folder with .sln file):
# docker-compose build
# docker-compose up
#
# RUN JUST THIS CONTAINER FROM ROOT (folder with .sln file):
# docker build --pull -t web -f src/Web/Dockerfile .
#
# RUN COMMAND
#  docker run --name eshopweb --rm -it -p 8080:8080 web
FROM microsoft/dotnet:2.2-sdk AS build
WORKDIR /app
COPY src /app

WORKDIR /app/Web
RUN dotnet restore \
    && dotnet publish -c Release -o out

FROM microsoft/dotnet:2.2-aspnetcore-runtime AS runtime
WORKDIR /app
COPY --from=build /app/Web/out .

# Optional: Set this here if not setting it from docker-compose.yml
# ENV ASPNETCORE_ENVIRONMENT Development
RUN groupadd -r devsecops \
    && useradd --no-log-init -r -g devsecops devsecops \
    && mkdir /home/devsecops \
    && chown -R devsecops /app \
    && chown -R devsecops /home/devsecops
ENV ASPNETCORE_URLS=http://+:8080
ENV eShopStorageAccountCS=${eShopStorageAccountCS}
USER devsecops
ENTRYPOINT ["dotnet", "Web.dll", "--environment=development"]
