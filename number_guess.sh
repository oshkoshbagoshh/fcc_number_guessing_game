#!/bin/bash

# Define a variable for the PSQL command to interact with the database
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

# Prompt the user to enter their username
echo "Enter your username:"
read USERNAME

# Retrieve user data from the database based on the entered username
USER_DATA=$($PSQL "SELECT user_id, games_played, best_game FROM users WHERE username='$USERNAME'")

# Check if the user is new or returning
if [[ -z $USER_DATA ]]; then
  # New user
  echo "Welcome, $USERNAME! It looks like this is your first time here."
  # Insert the new user into the database
  INSERT_USER_RESULT=$($PSQL "INSERT INTO users(username, games_played) VALUES('$USERNAME', 0)")
  # Retrieve the new user's ID
  USER_ID=$($PSQL "SELECT user_id FROM users WHERE username='$USERNAME'")
else
  # Returning user
  echo "$USER_DATA" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME; do
    echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
  done
fi

# Generate a random secret number between 1 and 1000
SECRET_NUMBER=$(( RANDOM % 1000 + 1 ))
# Initialize the guess counter
GUESSES=0

# Prompt the user to guess the secret number
echo "Guess the secret number between 1 and 1000:"

# Loop until the user guesses the correct number
while true; do
  read GUESS
  ((GUESSES++))

  # Check if the input is an integer
  if ! [[ $GUESS =~ ^[0-9]+$ ]]; then
    echo "That is not an integer, guess again:"
  elif (( GUESS < SECRET_NUMBER )); then
    echo "It's higher than that, guess again:"
  elif (( GUESS > SECRET_NUMBER )); then
    echo "It's lower than that, guess again:"
  else
    # Correct guess
    echo "You guessed it in $GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
    break
  fi
done

# Update the user's game statistics in the database
if [[ -z $USER_DATA ]]; then
  # Update the new user's game statistics
  UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=1, best_game=$GUESSES WHERE user_id=$USER_ID")
else
  # Update the returning user's game statistics
  echo "$USER_DATA" | while IFS="|" read USER_ID GAMES_PLAYED BEST_GAME; do
    NEW_GAMES_PLAYED=$(( GAMES_PLAYED + 1 ))
    # Update the best game if the current game has fewer guesses
    if [[ -z $BEST_GAME || $GUESSES -lt $BEST_GAME ]]; then
      UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED, best_game=$GUESSES WHERE user_id=$USER_ID")
    else
      UPDATE_USER_RESULT=$($PSQL "UPDATE users SET games_played=$NEW_GAMES_PLAYED WHERE user_id=$USER_ID")
    fi
  done
fi
