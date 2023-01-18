package client

import (
	"testing"

	"gotest.tools/assert"
)

func TestGetVersion(t *testing.T) {
	k8s := NewFakeK8s()
	got, err := k8s.GetVersion()
	if err != nil {
		t.Fatal("getVersion should not raise an error")
	}
	want := "v0.0.0-master+$Format:%H$"
	assert.Equal(t, want, got)
}
