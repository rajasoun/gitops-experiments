package client

import (
	"context"
)

// check cluster health
func (k8s *K8s) GetHealthStatus() (string, error) {
	health, err := k8s.Clientset.Discovery().RESTClient().Get().AbsPath("/healthz").DoRaw(context.Background())
	if err != nil {
		return "", err
	}
	if logEnabled {
		log.Infof("Cluster Health: %s", string(health))
	}
	return string(health), nil
}
