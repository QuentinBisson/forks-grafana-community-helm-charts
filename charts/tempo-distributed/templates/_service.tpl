{{/*
Service helper

Params:
  ctx                      = root context ($)
  component                = component values block (e.g. .Values.compactor)
  target                   = component name string (e.g. "compactor")
  grpcServiceEnabled       = bool, default false — emit a grpc port
  headlessServiceEnabled   = bool, default false — emit a headless (-headless) sibling Service
  publishNotReadyAddresses = bool, default false — set on headless service
*/}}
{{- define "tempo.service" -}}
{{- $ctx := .ctx -}}
{{- $component := .component -}}
{{- $target := .target -}}
{{- $grpcServiceEnabled := kindIs "bool" .grpcServiceEnabled | ternary .grpcServiceEnabled false -}}
{{- $headlessServiceEnabled := kindIs "bool" .headlessServiceEnabled | ternary .headlessServiceEnabled false -}}
{{- $publishNotReadyAddresses := kindIs "bool" .publishNotReadyAddresses | ternary .publishNotReadyAddresses false -}}
{{- with $ctx }}
apiVersion: v1
kind: Service
metadata:
  name: {{ include "tempo.resourceName" (dict "ctx" . "component" $target) }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "tempo.labels" (dict "ctx" . "component" $target) | nindent 4 }}
    {{- with $component.service.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $component.service.annotations }}
  annotations:
    {{- tpl (toYaml . | nindent 4) $ }}
  {{- end }}
spec:
  type: {{ $component.service.type | default "ClusterIP" }}
  ipFamilies: {{ .Values.tempo.service.ipFamilies }}
  ipFamilyPolicy: {{ .Values.tempo.service.ipFamilyPolicy }}
  ports:
    - name: http-metrics
      port: {{ include "tempo.serverHttpListenPort" . | trim | int }}
      targetPort: http-metrics
      protocol: TCP
    {{- if $grpcServiceEnabled }}
    - name: grpc
      port: {{ include "tempo.serverGrpcListenPort" . | trim | int }}
      targetPort: grpc
      protocol: TCP
      {{- with (dig "appProtocol" "grpc" "" $component) }}
      appProtocol: {{ . }}
      {{- end }}
    {{- end }}
  {{- with $component.service.internalTrafficPolicy }}
  internalTrafficPolicy: {{ . }}
  {{- end }}
  {{- if $component.service.loadBalancerIP }}
  loadBalancerIP: {{ $component.service.loadBalancerIP }}
  {{- end }}
  {{- with $component.service.externalTrafficPolicy }}
  externalTrafficPolicy: {{ . }}
  {{- end }}
  {{- with $component.service.loadBalancerSourceRanges }}
  loadBalancerSourceRanges:
    {{- toYaml . | nindent 4 }}
  {{- end }}
  selector:
    {{- include "tempo.selectorLabels" (dict "ctx" . "component" $target) | nindent 4 }}
{{- if $headlessServiceEnabled }}
---
apiVersion: v1
kind: Service
metadata:
  name: {{ printf "%s-headless" (include "tempo.resourceName" (dict "ctx" . "component" $target)) }}
  namespace: {{ .Release.Namespace }}
  labels:
    {{- include "tempo.labels" (dict "ctx" . "component" $target) | nindent 4 }}
    prometheus.io/service-monitor: "false"
    variant: headless
    {{- with $component.service.labels }}
    {{- toYaml . | nindent 4 }}
    {{- end }}
  {{- with $component.service.annotations }}
  annotations:
    {{- tpl (toYaml . | nindent 4) $ }}
  {{- end }}
spec:
  type: ClusterIP
  clusterIP: None
  ipFamilies: {{ .Values.tempo.service.ipFamilies }}
  ipFamilyPolicy: {{ .Values.tempo.service.ipFamilyPolicy }}
  {{- if $publishNotReadyAddresses }}
  publishNotReadyAddresses: {{ $publishNotReadyAddresses }}
  {{- end }}
  ports:
    - name: http-metrics
      port: {{ include "tempo.serverHttpListenPort" . | trim | int }}
      targetPort: http-metrics
      protocol: TCP
    {{- if $grpcServiceEnabled }}
    - name: grpc
      port: {{ include "tempo.serverGrpcListenPort" . | trim | int }}
      targetPort: grpc
      protocol: TCP
      {{- with (dig "appProtocol" "grpc" "" $component) }}
      appProtocol: {{ . }}
      {{- end }}
    {{- end }}
  selector:
    {{- include "tempo.selectorLabels" (dict "ctx" . "component" $target) | nindent 4 }}
{{- end }}
{{- end }}
{{- end }}
