bit lift_switch[3] // Switches present in the elevator
bit floor_switch[3] // Switches present on the floors

bit door_state // 1 for open and 0 for closed

byte curr_floor // current floor of the elevator - Should take values 0, 1, 2

bit motion_direction // 0 for down, 1 for up

// Type of messages to be passed among the processes
mtype = {open_door, close_door, move_up, move_down, stop, press_floor_button, press_elevator_button}

// Channel definitions
chan to_elevator = [0] of { mtype } // Channel to send instructions from controller to elevator
chan button_press = [0] of { mtype, byte} // Channel to record button presses

// Models the elevator controller
active proctype elevator_controller()
{
	curr_floor = 0;
	motion_direction = 0; // Initially assumed to be going downwards

start: 
	to_elevator!close_door // Instruct the elevator to close doors

check_direction: 
	if 
	:: curr_floor == 0 -> motion_direction = 1 // If at lowest floor, move up
	:: curr_floor == 2 -> motion_direction = 0 // If at highest floor, move down
	:: else -> goto move_up_or_down // Otherwise don't change
	fi

move_up_or_down:
	if
	:: motion_direction == 0 -> goto upward_motion
	:: motion_direction == 1 -> goto downward_motion
	:: else -> skip // TODO: Throw some error in this state
	fi

upward_motion:
	curr_floor = curr_floor + 1;
	to_elevator!move_up; // Instruct the elevator to move up
	goto check_open_or_change_direction

downward_motion:
	curr_floor = curr_floor - 1;
	to_elevator!move_down; // Instruct the elevator to move downwards
	goto check_open_or_change_direction

check_open_or_change_direction:
	if
	:: lift_switch[curr_floor] == 1 -> to_elevator!stop -> goto unpress_button
	:: floor_switch[curr_floor] == 1 -> to_elevator!stop -> goto unpress_button
	:: else -> goto check_direction
	fi

unpress_button:
	lift_switch[curr_floor] = 0; floor_switch[curr_floor] = 0; to_elevator!open_door;
	goto start
}

// Models the elevator
active proctype elevator()
{
	door_state = 1

start:
	to_elevator?close_door -> door_state = 0; // Close door and update door state

wait_for_move:
	if
	:: to_elevator?move_up -> goto moving_upward
	:: to_elevator?move_down -> goto moving_downward
	:: to_elevator?open_door -> door_state = 1 -> goto start
	:: else -> skip // TODO: Throw some error here
	fi

moving_upward:
	if
	:: to_elevator?move_up -> goto moving_upward
	:: to_elevator?stop -> goto wait_for_move
	:: else -> skip // TODO: Throw some error here
	fi

moving_downward:
	if
	:: to_elevator?move_down -> goto moving_downward
	:: to_elevator?stop -> goto wait_for_move
	:: else -> skip // TODO: Throw some error here
	fi
}

// Models the elevator and floor button presses
active proctype press_buttons()
{

}

// Records the button presses for the controller
active proctype record_button_presses()
{

}