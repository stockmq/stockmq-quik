package quik

func (q *Quik) IsConnected() (int, error) {
	return CallTyped[int](q, "isConnected")
}

func (q *Quik) GetScriptPath() (string, error) {
	return CallTyped[string](q, "getScriptPath")
}
