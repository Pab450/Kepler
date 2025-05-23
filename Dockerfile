##############
# BASE STAGE #
##############

FROM alpine:3.20 AS base

# Add OpenJDK17
RUN apk add --no-cache openjdk17

# Uses /kepler directory
WORKDIR /kepler

###############
# BUILD STAGE #
###############

FROM base AS build

# Add unzip
RUN apk add --no-cache unzip

# Copy every files/folders that are not in .dockerignore
COPY . .

# Convert CRLF to LF executable files (failing build for Windows without this)
RUN sed -i 's/\r$//' gradlew tools/scripts/run.sh

# Make gradlew and run.sh executable
RUN chmod +x gradlew tools/scripts/run.sh

# Run gradle build
RUN ./gradlew distZip

# Unzip builded Kepler server
RUN unzip -qq ./Kepler-Server/build/distributions/Kepler-Server.zip -d ./release

# Prepare build directory
RUN rm -rf ./release/Kepler-Server/bin && \
    mkdir -p ./build/lib && \
    mv ./release/Kepler-Server/lib/Kepler-Server.jar ./build/kepler.jar && \
    mv ./release/Kepler-Server/lib/* ./build/lib && \
    cp tools/scripts/run.sh ./build/

####################
# PRODUCTION STAGE #
####################

FROM base AS production

# Copy builded Kepler server
COPY --from=build /kepler/build ./

CMD [ "sh", "run.sh" ]
