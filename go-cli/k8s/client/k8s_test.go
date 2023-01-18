package client

import (
	"k8s.io/client-go/kubernetes/fake"
)

func NewFakeK8s() *K8s {
	client := K8s{}
	client.Clientset = fake.NewSimpleClientset()
	return &client
}
