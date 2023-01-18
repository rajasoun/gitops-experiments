package client

import (
	"fmt"
)

// GetVersion returns the version of the kubernetes cluster that is running
func (o *K8s) GetVersion() (string, error) {
	version, err := o.Clientset.Discovery().ServerVersion()
	if err != nil {
		return "", err
	}
	if logEnabled {
		log.Infof("Version of running k8s %v", version)
	}
	return fmt.Sprintf("%s", version), nil
}
