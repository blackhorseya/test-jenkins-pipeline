# build statge - backend
FROM mcr.microsoft.com/dotnet/core/sdk:3.1-alpine AS dotnet-build
WORKDIR /app
COPY ./*.sln .
COPY src/*/*.csproj ./
RUN for file in $(ls *.csproj); do mkdir -p src/${file%.*}/ && mv $file src/${file%.*}/; done
RUN dotnet restore ./src/${CSPROJECT_NAME}/
COPY ./src ./src
RUN dotnet publish src/${CSPROJECT_NAME} -c Release -o out

FROM mcr.microsoft.com/dotnet/core/aspnet:3.1-alpine AS runtime
WORKDIR /app
ENV DOTNET_SYSTEM_GLOBALIZATION_INVARIANT=false
RUN apk add --no-cache icu-libs
COPY --from=dotnet-build /app/out ./
ENTRYPOINT ["dotnet", "${CSPROJECT_NAME}.dll"]