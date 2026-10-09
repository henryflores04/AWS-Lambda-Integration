FROM public.ecr.aws/lambda/nodejs:20 AS build

WORKDIR /var/task

COPY package.json package-lock.json* ./
RUN npm install --omit=dev --no-bin-links

FROM scratch AS export
COPY --from=build /var/task/node_modules /node_modules