# Get n jokes from https://jokeapi.dev/
export def more [
  n: int,     # number of jokes to get max 10
]: [
  nothing -> table
] {
  http get $"https://v2.jokeapi.dev/joke/Programming,Pun?blacklistFlags=nsfw,religious,political,racist,sexist,explicit&type=single&idRange=(random int 0..200)-(random int 201..318)&amount=($n)" | get jokes.joke 
}
