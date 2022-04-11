import sys.io.Process;
import haxe.Exception;
import captain.Command;

var format:String = " <task-name> (<task-project>) <elapsed-time>";
var formatInactive:String = "%{F#6b6b6b} Start a new task%{F-}";
var notifications:Bool = true;

class Task {
	public var id:Null<Int> = null;
	public var description:String = "";
	public var project:String = "";
	public var startedAt:Null<Date> = null;
	public var endedAt:Null<Date> = null;

	public function new() {}

	public function isActive():Bool {
		return this.endedAt == null;
	}

	public function elapsedTime() {}
}

function exec(cmd:String) {
	return new Process(cmd).stdout.readAll().toString();
}

function parseDate(str:String):Null<Date> {
	if (str == '---') {
		return null;
	}
	return Date.fromString(StringTools.replace(str, 'T', ' '));
}

function sendNotification(title:String, summary:String):Void {
	if (notifications) {
		Sys.command('notify-send "$title" "$summary"');
	}
}

class DTracker {
	public var tasks:Array<Task> = [];
	public var projects:Array<String> = [];

	public static final instance:DTracker = new DTracker();

	private function new() {
		this.checkIfInstalled();
		this.fetchTodayTasks();
	}

	public function checkIfInstalled() {
		if (exec('which d-tracker-cli').length == 0) {
			throw new Exception('Could not find d-tracker-cli in path');
		}
	}

	public function fetchTodayTasks():Void {
		var lines = exec('d-tracker-cli list-today-tasks | sed 1,2d').split('\n');

		for (line in lines) {
			if (line.length > 0) {
				var data = line.split('|');
				var task = new Task();
				task.id = Std.parseInt(data[0]);
				task.description = data[4];
				task.project = data[1];
				task.startedAt = parseDate(data[2]);
				task.endedAt = parseDate(data[3]);
				this.tasks.push(task);
			}
		}
	}

	public function createTask(task:Task):Void {
		if (task.description.length == 0) {
			throw new Exception('The task description cannot be empty');
		}
		if (task.project.length == 0) {
			throw new Exception('The task project cannot be empty');
		}
	}

	public function getActiveTask():Null<Task> {
		var tasks = this.tasks;
		tasks.reverse();
		for (task in tasks) {
			if (task.isActive()) {
				return task;
			}
		}
		return null;
	}
}

final class DTrackerControl {
	static public function main() {
		var command = new Command(Sys.args());

		command.arguments = [
			{
				name: "action",
				description: "output, new, stop, toggle",
			},
		];

		command.options = [
			{
				name: "help",
				shortName: "h",
				description: "Print this help message.",
				boolean: true,
			},
			{
				name: "format",
				shortName: "f",
				description: "Set the format for the output.",
			},
			{
				name: "format-inactive",
				shortName: "i",
				description: "Set the format for the inactive state.",
			},
			{
				name: "notifications",
				shortName: "n",
				description: "Enable or disable notifications.",
			},
		];

		if (command.getOption("help") != None) {
			Sys.println(command.getInstructions());
			return;
		}

		switch (command.getArgument("action")) {
			case Some(value):
				{
					switch (value) {
						case "output": {
								var task = DTracker.instance.getActiveTask();
								if (task != null) {
									Sys.println(task.description);
								} else {
									Sys.println("No task started");
								}
							}
						case "new": {
								sendNotification("", "");
							}
						case "stop": {
								var task = DTracker.instance.getActiveTask();
								if (task != null) {
									Sys.command("d-tracker-cli stop-in-progress");
									sendNotification("Task stopped", [
										'Description: ${task.description}',
										'Project: ${task.project}',
										'Started At: ${DateTools.format(task.startedAt, "%T")}',
										'Stopped At: ${DateTools.format(Date.now(), "%T")}'
									].join('\n'));
								}
							}
					}
				}
			case None:
				{
					Sys.println(command.getInstructions());
				}
		};
	}
}
