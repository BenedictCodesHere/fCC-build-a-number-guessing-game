#!/bin/bash

PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

START_GAME(){
    # Read the user input with the -p flag which echoes the message first
   echo "Enter your username:" 
   read USERNAME 
    # Query preexisting game data to see if user has played before
    check_username=$($PSQL "SELECT * from game_data WHERE username='$USERNAME'")
    # If they have, then 
    if [[ $check_username ]] 
    then
        # set IFS for particular case usage
        IFS='|'
        read -ra parts <<< "$check_username"
        echo -e "parts is $parts"
        
        username=${parts[0]}
        games_played=${parts[1]}
        best_game=${parts[2]}
        # set IFS back to normal
        IFS=$' \t\n'
        # tell them their stats
        echo "Welcome back, $username! You have played $games_played games, and your best game took $best_game guesses."
        # run game
        RUN_GAME
    else
        echo "Welcome, $USERNAME! It looks like this is your first time here."
        # run game
        RUN_GAME
    fi
}

GUESS_PROMPT(){
    # prompt the user to make a guess and then update the variable
    echo "Guess the secret number between 1 and 1000:" 
    read USER_GUESS
    # if number is not a valid guess
    if [[ "$USER_GUESS" -lt 1 ]] || [[ "$USER_GUESS" -gt 1000 ]] || [[ ! "$USER_GUESS" =~ ^[0-9]+$ ]]
    then
        echo "That is not an integer, guess again:"
        # re-prompt
        GUESS_PROMPT
    fi
}

RUN_GAME(){
    # increment the games played variable
    ((games_played++))
    # Create secret_number variable by grabbing random number from numbers
    secret_number=$($PSQL "SELECT number FROM numbers ORDER BY RANDOM() LIMIT 1")
    # initialize guess_counter variable and user guess variable
    number_of_guesses=0
    USER_GUESS=0
      
    # check if user_guess matches the secret_number
     # while they don't match, keep running the guess prompt and higher/lower prompt
    while [[ "$USER_GUESS" != "$secret_number" ]]
    do
        GUESS_PROMPT
        ((number_of_guesses++))
        # if USER_GUESS does not match secret_number
         # if USER_GUESS -gt secret_number
        if [[ "$USER_GUESS" -gt "$secret_number" ]]
        then
            # tell user that guess is higher than secret number
            echo -e "It's lower than that, guess again:"
        else
            # tell user that guess is lower than secret number
            echo -e "It's higher than that, guess again:"
        fi
    done
        # loop exit when equivalent so then
        echo "You guessed it in $number_of_guesses tries. The secret number was $secret_number. Nice job!"
        # update the database with variables
        UPDATE_DB
}

UPDATE_DB(){
  # FIRST TIME UPDATE
    # query to see if best game exists
    query_best_game=$($PSQL "SELECT best_game FROM game_data WHERE username='$USERNAME'")
    # if best game is empty
    if [[ -z $query_best_game ]]
    then
        # update with username, games_played, best_game
        $PSQL "INSERT INTO game_data(username, games_played, best_game) VALUES('$USERNAME', $games_played, $number_of_guesses)"
    else
      # NOT FIRST TIME UPDATE
        # check if query_best_game > number_of_guesses
        # if current guess score is better than best score
        if [[ "$number_of_guesses" -lt "$query_best_game" ]]
        then
            # input new best score and incremented games_played variable
            $PSQL "UPDATE game_data SET games_played=$games_played, best_game=$number_of_guesses WHERE username='$USERNAME'"
        else 
            # if best score is better than new guess score
           $PSQL "UPDATE game_data SET games_played=$games_played WHERE username='$USERNAME'"
        fi
    fi

}


START_GAME