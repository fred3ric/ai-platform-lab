# Application racine d'Argo CD. Rendue par scripts/up.sh avec envsubst.
# Variables : PROFILE, ARGOCD_NAMESPACE, REPO_URL, GITOPS_REVISION.
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root
  namespace: ${ARGOCD_NAMESPACE}
spec:
  project: default
  source:
    repoURL: ${REPO_URL}
    targetRevision: ${GITOPS_REVISION}
    path: gitops/profiles/${PROFILE}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGOCD_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
