/*
==========================================================================
|                           Game: Plutonium IW5                          |
|               Description : Display text and run GSC code              | 
|                      by typing commands in the chat                    |
|                             Author: Resxt                              |
==========================================================================
| https://github.com/Resxt/Plutonium-IW5-Scripts/tree/main/small_scripts |
==========================================================================
*/



/* Init section */

Init() 
{
    InitChatCommands();
}

InitChatCommands()
{
    level.commands_prefix = "!";
    level.commands_servers_ports = ["27016", "27017", "27018"];

    InitCommands();

    level thread ChatListener();
}

InitCommands()
{
    // All servers text commands
    CreateCommand(level.commands_servers_ports, "help", "text", ["Type " + level.commands_prefix + "commands to get a list of commands", "Type " + level.commands_prefix + "help followed by a command name to see how to use it"]);

    // All servers function commands
    CreateCommand(level.commands_servers_ports, "map", "function", ::ChangeMapCommand, ["Example: " + level.commands_prefix + "map mp_dome"]);
    CreateCommand(level.commands_servers_ports, "mode", "function", ::ChangeModeCommand, ["Example: " + level.commands_prefix + "mode FFA_default"]);
    CreateCommand(level.commands_servers_ports, "mapmode", "function", ::ChangeMapAndModeCommand, ["Example: " + level.commands_prefix + "mapmode mp_seatown TDM_default"]);

    // Specific server(s) text commands
    CreateCommand(["27016", "27017"], "rules", "text", ["Do not camp", "Do not spawnkill", "Do not disrespect other players"]);
    CreateCommand(["27018"], "rules", "text", ["Leave your spot and don't camp after using a M.O.A.B", "Don't leave while being infected", "Do not disrespect other players"]);

    // Specific server(s) function commands
    CreateCommand(["27016", "27017"], "suicide", "function", ::SuicideCommand);
}

/*
<serverPorts> the ports of the servers this command will be created for
<commandName> the name of the command, this is what players will type in the chat
<commandType> the type of the command: <text> is for arrays of text to display text in the player's chat and <function> is to execute a function
*/
CreateCommand(serverPorts, commandName, commandType, commandValue, commandHelp)
{
    foreach (serverPort in serverPorts)
    {
        level.commands[serverPort][commandName]["type"] = commandType;

        if (IsDefined(commandHelp))
        {
            level.commands[serverPort][commandName]["help"] = commandHelp;
        }
    
        if (commandType == "text")
        {
            level.commands[serverPort][commandName]["text"] = commandValue;
        }
        else if (commandType == "function")
        {
            level.commands[serverPort][commandName]["function"] = commandValue;
        }
    }
}



/* Chat section */

ChatListener()
{
    while (true) 
    {
        level waittill("say", message, player);

        if (message[0] != level.commands_prefix) // For some reason checking for the buggy character doesn't work so we start at the second character if the first isn't the command prefix
        {
            message = GetSubStr(message, 1); // Remove the random/buggy character at index 0, get the real message
        }

        if (message[0] != level.commands_prefix) // If the message doesn't start with the command prefix
        {
            continue; // stop
        }

        commandArray = StrTok(message, " "); // Separate the command by space character. Example: ["!map", "mp_dome"]
        command = commandArray[0]; // The command as text. Example: !map
        args = []; // The arguments passed to the command. Example: ["mp_dome"]

        for (i = 1; i < commandArray.size; i++)
        {
            args[args.size] = commandArray[i];
        }

        // commands command
        if (command == level.commands_prefix + "commands")
        {
            player thread TellPlayer(GetArrayKeys(level.commands[GetDvar("net_port")]), 2, true);
        }
        else
        {
            // help command
            if (command == level.commands_prefix + "help" && !IsDefined(level.commands[GetDvar("net_port")]["help"]) || command == level.commands_prefix + "help" && IsDefined(level.commands[GetDvar("net_port")]["help"]) && args.size >= 1)
            {
                if (args.size < 1)
                {
                    player thread TellPlayer(NotEnoughArgsError(1), 1.5);
                }
                else
                {
                    commandValue = level.commands[GetDvar("net_port")][args[0]];

                    if (IsDefined(commandValue))
                    {
                        commandHelp = commandValue["help"];

                        if (IsDefined(commandHelp))
                        {
                            player thread TellPlayer(commandHelp, 1.5);
                        }
                        else
                        {
                            player thread TellPlayer(CommandHelpDoesNotExistError(args[0]), 1);
                        }
                    }
                    else
                    {
                        if (args[0] == "commands")
                        {
                            player thread TellPlayer(CommandHelpDoesNotExistError(args[0]), 1);
                        }
                        else
                        {
                            player thread TellPlayer(CommandDoesNotExistError(args[0]), 1);
                        }
                    }
                }
            }
            // any other command
            else
            {
                commandName = GetSubStr(command, 1);
                commandValue = level.commands[GetDvar("net_port")][commandName];

                if (IsDefined(commandValue))
                {
                    if (commandValue["type"] == "text")
                    {
                        player thread TellPlayer(commandValue["text"], 2);
                    }
                    else if (commandValue["type"] == "function")
                    {
                        error = player [[commandValue["function"]]](args);

                        if (IsDefined(error))
                        {
                            player thread TellPlayer(error, 1.5);
                        }
                    }
                }
                else
                {
                    player thread TellPlayer(CommandDoesNotExistError(commandName), 1);
                }
            }
        }
    }
}

TellPlayer(messages, waitTime, isCommand)
{
    for (i = 0; i < messages.size; i++)
    {
        message = messages[i];

        if (IsDefined(isCommand) && isCommand)
        {
            message = level.commands_prefix + message;
        }

        self tell(message);
        
        if (i < (messages.size - 1)) // Don't unnecessarily wait after the last message has been displayed
        {
            wait waitTime;
        }
    }
}



/* Command functions section */

SuicideCommand(args)
{
    self Suicide();
}

ChangeMapCommand(args)
{
    if (args.size < 1)
    {
        return NotEnoughArgsError(1);
    }

    ChangeMap(args[0]);
}

ChangeModeCommand(args)
{
    if (args.size < 1)
    {
        return NotEnoughArgsError(1);
    }

    ChangeMode(args[0], true);
}

ChangeMapAndModeCommand(args)
{
    if (args.size < 2)
    {
        return NotEnoughArgsError(2);
    }

    ChangeMode(args[1], false);
    ChangeMap(args[0]);
}



/* Logic functions section */

ChangeMap(mapName)
{
    cmdexec("map " + mapName);
}

ChangeMode(modeName, restart)
{
    cmdexec("load_dsr " + modeName + ";");

    if (restart)
    {
        cmdexec("map_restart");
    }
}



/* Error functions section */

CommandDoesNotExistError(commandName)
{
    return ["The command " + commandName + " doesn't exist", "Type " + level.commands_prefix + "commands to get a list of commands"];
}

CommandHelpDoesNotExistError(commandName)
{
    return ["The command " + commandName + " doesn't have any help message"];
}

NotEnoughArgsError(minimumArgs)
{
    return ["Not enough arguments supplied", "At least " + minimumArgs + " argument expected"];
}
