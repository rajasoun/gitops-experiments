package client

import (
	"context"
)

// check cluster health
func (o *K8s) GetHealthStatus() (string, error) {
	health, err := o.Clientset.Discovery().RESTClient().Get().AbsPath("/healthz").DoRaw(context.Background())
	if err != nil {
		return "", err
	}
	if logEnabled {
		log.Infof("Cluster Health: %s", string(health))
	}
	return string(health), nil
}
