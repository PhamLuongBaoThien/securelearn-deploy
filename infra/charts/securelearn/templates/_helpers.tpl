{{- define "securelearn.name" -}}{{ default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "securelearn.fullname" -}}{{ default .Release.Name .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}{{- end }}
{{- define "securelearn.labels" -}}
app.kubernetes.io/part-of: securelearn
app.kubernetes.io/managed-by: {{ .Release.Service }}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | quote }}
{{- end }}
