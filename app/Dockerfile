
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

COPY ["api/TodoApi.csproj", "api/"]
COPY ["worker/worker.csproj", "worker/"]
RUN dotnet restore "api/TodoApi.csproj"
RUN dotnet restore "worker/worker.csproj"


COPY . .

RUN dotnet publish "api/TodoApi.csproj" -c Release -o /app/publish/api

RUN dotnet publish "worker/worker.csproj" -c Release -o /app/publish/worker

FROM mcr.microsoft.com/dotnet/aspnet:8.0 AS final
WORKDIR /app

COPY --from=build /app/publish .

EXPOSE 8080
ENV ASPNETCORE_URLS=http://+:8080

ENTRYPOINT ["dotnet", "api/TodoApi.dll"]