# Build stage
FROM mcr.microsoft.com/dotnet/sdk:8.0 AS build
WORKDIR /src

# Copy solution and project files for dependency restoration
COPY *.sln ./
COPY Implem.Pleasanter/Implem.Pleasanter.csproj ./Implem.Pleasanter/
COPY Implem.CodeDefiner/Implem.CodeDefiner.csproj ./Implem.CodeDefiner/
COPY Implem.Libraries/Implem.Libraries.csproj ./Implem.Libraries/
COPY Implem.DefinitionAccessor/Implem.DefinitionAccessor.csproj ./Implem.DefinitionAccessor/
COPY Implem.DisplayAccessor/Implem.DisplayAccessor.csproj ./Implem.DisplayAccessor/
COPY Implem.ParameterAccessor/Implem.ParameterAccessor.csproj ./Implem.ParameterAccessor/
COPY Implem.Factory/Implem.Factory.csproj ./Implem.Factory/
COPY Implem.Plugins/Implem.Plugins.csproj ./Implem.Plugins/
COPY Rds/Implem.IRds/Implem.IRds.csproj ./Rds/Implem.IRds/
COPY Rds/Implem.PostgreSql/Implem.PostgreSql.csproj ./Rds/Implem.PostgreSql/
COPY Rds/Implem.SqlServer/Implem.SqlServer.csproj ./Rds/Implem.SqlServer/
COPY Rds/Implem.MySql/Implem.MySql.csproj ./Rds/Implem.MySql/

# Restore dependencies
RUN dotnet restore Implem.Pleasanter/Implem.Pleasanter.csproj
RUN dotnet restore Implem.CodeDefiner/Implem.CodeDefiner.csproj

# Copy source code
COPY Implem.Pleasanter/ ./Implem.Pleasanter/
COPY Implem.CodeDefiner/ ./Implem.CodeDefiner/
COPY Implem.Libraries/ ./Implem.Libraries/
COPY Implem.DefinitionAccessor/ ./Implem.DefinitionAccessor/
COPY Implem.DisplayAccessor/ ./Implem.DisplayAccessor/
COPY Implem.ParameterAccessor/ ./Implem.ParameterAccessor/
COPY Implem.Factory/ ./Implem.Factory/
COPY Implem.Plugins/ ./Implem.Plugins/
COPY Rds/ ./Rds/

# Copy custom Rds.json for Docker environment
COPY Rds.docker.json ./Implem.Pleasanter/App_Data/Parameters/Rds.json

# Copy Api.json for CodeDefiner
COPY Implem.Pleasanter/App_Data/Parameters/Api.json ./Implem.Pleasanter/App_Data/Parameters/Api.json
# Copy Env.json for CodeDefiner
COPY Implem.Pleasanter/App_Data/Parameters/Env.json ./Implem.Pleasanter/App_Data/Parameters/Env.json

# Build and publish Pleasanter
WORKDIR /src/Implem.Pleasanter
RUN dotnet publish -c Release -o /app/publish --no-restore

# Build and publish CodeDefiner
WORKDIR /src/Implem.CodeDefiner
RUN dotnet publish -c Release -o /app/publish --no-restore

# Runtime stage
FROM mcr.microsoft.com/dotnet/aspnet:8.0
WORKDIR /app
COPY --from=build /app/publish .

# Copy the custom Rds.json for Docker environment
COPY <<EOF /app/App_Data/Parameters/Rds.json
{
  "Dbms": "PostgreSQL",
  "Provider": "Local",
  "SaConnectionString": "Server=db;Database=pleasanter;UID=sa;PWD=pleasanter",
  "OwnerConnectionString": "Server=db;Database=#ServiceName#;UID=#ServiceName#_Owner;PWD=SetAdminsPWD",
  "UserConnectionString": "Server=db;Database=#ServiceName#;UID=#ServiceName#_User;PWD=SetUsersPWD",
  "SqlCommandTimeOut": 0,
  "MinimumTime": 3,
  "DeadlockRetryCount": 4,
  "DeadlockRetryInterval": 1000,
  "DisableIndexChangeDetection": false
}
EOF

# Copy Api.json for CodeDefiner
COPY <<EOF /app/App_Data/Parameters/Api.json
{
  "Api": {
    "Enabled": true,
    "Items": {
      "Get": true,
      "Create": true,
      "Update": true,
      "Delete": true
    }
  }
}
EOF

# Create entrypoint script
COPY <<EOF /app/entrypoint.sh
#!/bin/bash
if [ "\$1" = "_rds" ] || [ "\$1" = "rds" ] || [ "\$1" = "def" ] || [ "\$1" = "_def" ]; then
    # Run CodeDefiner
    exec dotnet Implem.CodeDefiner.dll "\$@"
else
    # Run Pleasanter
    exec dotnet Implem.Pleasanter.dll
fi
EOF

RUN chmod +x /app/entrypoint.sh

ENTRYPOINT ["/app/entrypoint.sh"] 