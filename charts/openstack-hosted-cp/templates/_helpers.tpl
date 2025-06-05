{{/*
Expand the name of the chart.
*/}}
{{- define "openstack-hosted-cp.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "openstack-hosted-cp.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "openstack-hosted-cp.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "openstack-hosted-cp.labels" -}}
helm.sh/chart: {{ include "openstack-hosted-cp.chart" . }}
{{ include "openstack-hosted-cp.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "openstack-hosted-cp.selectorLabels" -}}
app.kubernetes.io/name: {{ include "openstack-hosted-cp.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get network reference for existing networks
*/}}
{{- define "openstack-hosted-cp.networkRef" -}}
{{- if .Values.existingNetwork.id }}
id: {{ .Values.existingNetwork.id }}
{{- else }}
filter:
  name: {{ .Values.existingNetwork.name }}
{{- end }}
{{- end }}

{{/*
Get subnet reference for existing networks
*/}}
{{- define "openstack-hosted-cp.subnetRef" -}}
{{- if .Values.existingSubnet.id }}
id: {{ .Values.existingSubnet.id }}
{{- else }}
filter:
  name: {{ .Values.existingSubnet.name }}
{{- end }}
{{- end }}

{{/*
Cluster name
*/}}
{{- define "cluster.name" -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
OpenStack machine template names
*/}}
{{- define "openstackmachinetemplate.worker.name" -}}
    {{- include "cluster.name" . }}-worker-mt
{{- end }}

{{/*
K0s control plane name
*/}}
{{- define "k0smotroncontrolplane.name" -}}
    {{- include "cluster.name" . }}-cp
{{- end }}

{{/*
K0s worker config template name
*/}}
{{- define "k0sworkerconfigtemplate.name" -}}
    {{- include "cluster.name" . }}-machine-config
{{- end }}

{{/*
Machine deployment name
*/}}
{{- define "machinedeployment.name" -}}
    {{- include "cluster.name" . }}-md
{{- end }} 