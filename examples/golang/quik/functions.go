package quik

func (q *Quik) IsConnected() bool {
	return Call[bool](q, "isConnected")
}

func (q *Quik) GetScriptPath() string {
	return Call[string](q, "getScriptPath")
}

func (q *Quik) GetSecurityInfo(board string, ticker string) map[string]interface{} {
	return Call[map[string]interface{}](q, "getSecurityInfo", board, ticker)
}
