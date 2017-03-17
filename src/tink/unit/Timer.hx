package tink.unit;

interface Timer {
	function stop():Void;
}

interface TimerManager {
	function schedule(ms:Int, f:Void->Void):Timer;
}