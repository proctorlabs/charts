{{ define "deploy.volume_claims" -}}
{{- $data_name := print .Release.Name "-data" -}}
- name: {{ $data_name | quote }}
  persistentVolumeClaim:
    claimName: {{ include "lib.pvc_name" . | quote }}
{{- end }}

{{ define "deploy.volume_mappings" -}}
{{- $pvc_mount_path := .Values.volume.path -}}
{{- $data_name := print .Release.Name "-data" -}}
- name: {{ $data_name | quote }}
  mountPath: {{ $pvc_mount_path | quote }}
{{- end }}

{{ define "deploy.container_options" -}}
{{- end }}

{{ define "lib.deployment" }}
{{ $image := .Values.image }}
{{ $replicas := .Values.replicaCount }}
{{ $resources := .Values.resources }}
{{ $arch := $resources.arch }}
{{ $limits := $resources.limits }}
{{ $requests := $resources.requests }}
{{ $nodeselector := .Values.nodeselector }}

apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "lib.rel_name" . | quote }}
  namespace: {{ include "lib.namespace" . | quote }}
{{- include "lib.labels" . | indent 2 }}
spec:
  replicas: {{ $replicas }}
  selector:
    matchLabels:
      selfhosted.appname: {{ include "lib.rel_name" . | quote }}
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        selfhosted.appname: {{ include "lib.rel_name" . | quote }}
    spec:
      nodeSelector:
        {{- if $arch }}
        kubernetes.io/arch: {{ $arch | quote }}
        {{- end }}
        {{- range $key, $val := $nodeselector }}
        {{ $key }}: {{ $val | quote }}
        {{- end }}
      tolerations:
{{ .Values.tolerations | toYaml | indent 8 }}
      containers:
        - image: {{ $image.repository | quote }}
          name: {{ include "lib.rel_name" . | quote }}
          env:
{{- range $key, $val := $image.env }}
            - name: {{ $key | upper | quote }}
              value: {{ $val | quote }}
{{- end }}
          imagePullPolicy: "{{ $image.pullPolicy }}"
{{ include "deploy.container_options" . | indent 10 }}
          resources:
            limits:
{{ $limits | toYaml | indent 14 }}
            requests:
{{ $requests | toYaml | indent 14 }}
          volumeMounts:
{{ include "deploy.volume_mappings" . | indent 12 }}
          ports:
            - containerPort: {{ $image.port }}
      volumes:
{{ include "deploy.volume_claims" . | indent 8 }}
      restartPolicy: Always

{{ end }}
