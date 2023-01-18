package client

// GetVersion returns the version of the kubernetes cluster that is running
func (k8s *K8s) GetVersion() (string, error) {
	version, err := k8s.Clientset.Discovery().ServerVersion()
	if err != nil {
		return "", err
	}
	if logEnabled {
		log.Infof("Version of running k8s %v", version)
	}
	//return fmt.Sprintf("%s.%s", version.Major, version.Minor), nil
	return version.String(), nil
}
