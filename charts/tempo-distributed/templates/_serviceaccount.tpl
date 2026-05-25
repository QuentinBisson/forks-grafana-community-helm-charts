{{/*
ServiceAccount helper

Emits a ServiceAccount for a component when $component.serviceAccount.create is true.
By default components use the chart-level ServiceAccount; set create: true to opt in.

Params:
  ctx       = root context ($)
  component = component values block (e.g. .Values.compactor)
  target    = component name string (e.g. "compactor")
*/}}
{{- define "tempo.serviceAccount" -}}
{{- $ctx := .ctx -}}
{{- $component := .component -}}
{{- $target := .target -}}
{{- if $component.serviceAccount.create -}}
{{- with $ctx }}
apiVersion: v1
kind: ServiceAccount
metadata:
  name: {{ $component.serviceAccount.name | default (include "tempo.resourceName" (dict "ctx" . "component" $target)) }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "tempo.labels" (dict "ctx" . "component" $target) | nindent 4 }}
    {{- with $component.serviceAccount.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $component.serviceAccount.annotations }}
  annotations:
    {{- toYaml . | nindent 4 }}
  {{- end }}
automountServiceAccountToken: {{ $component.serviceAccount.automountServiceAccountToken }}
{{- with $component.serviceAccount.imagePullSecrets }}
imagePullSecrets:
  {{- toYaml . | nindent 2 }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
