package client

import (
	"os"

	"github.com/rajasoun/k8s/logger"
	coreClient "k8s.io/client-go/kubernetes"
	restClient "k8s.io/client-go/rest"
	cmdClient "k8s.io/client-go/tools/clientcmd"
	metricsClient "k8s.io/metrics/pkg/client/clientset/versioned"
)

// K8s struct holds the instance of clientset and metrics clisentset
type K8s struct {
	Clientset        coreClient.Interface
	MetricsClientSet *metricsClient.Clientset
	RestConfig       *restClient.Config
}

var (
	logEnabled bool
	log        = logger.New()
)

// NewK8s will provide a new k8s client interface
// resolves where it is running whether inside the kubernetes cluster or outside
// While running outside of the cluster, tries to make use of the kubeconfig file
// While running inside the cluster resolved via pod environment uses the in-cluster config
func NewK8s() (*K8s, error) {
	client := K8s{}
	_, logEnabled = os.LookupEnv("CLIENTSET_LOG")

	config, err := restClient.InClusterConfig()
	if err != nil {
		kubeConfig := cmdClient.NewDefaultClientConfigLoadingRules().GetDefaultFilename()
		config, err = cmdClient.BuildConfigFromFlags("", kubeConfig)
		if err != nil {
			return nil, err
		}
		if logEnabled {
			log.Info("Program running from outside of the cluster")
		}
	} else {
		if logEnabled {
			log.Info("Program running inside the cluster, picking the in-cluster configuration")
		}
	}
	client.Clientset, err = coreClient.NewForConfig(config)
	if err != nil {
		return nil, err
	}

	client.MetricsClientSet, err = metricsClient.NewForConfig(config)
	if err != nil {
		return nil, err
	}

	client.RestConfig = config
	return &client, nil
}
