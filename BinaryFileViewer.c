#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define STRING_LENGTH 8192
#define CHAR_SIZE 8

static char binary[STRING_LENGTH] = {0};
static char decimal[STRING_LENGTH * CHAR_SIZE] = {0};

extern char *binToDec(char *binary, size_t size, char *decimal);
extern char *binToHex(char *binary, size_t size, char *hexadecimal);

int readFile(const char *filePath, long *fPos) {
  FILE *file = fopen(filePath, "rb");
  if (file == NULL) {
    perror(filePath);
    return -1;
  }

  fseek(file, *fPos, SEEK_SET);

  int retVal = 0;
  if (fread(binary, 1, STRING_LENGTH, file) == STRING_LENGTH) {
    retVal = 0;
  } else {
    if (feof(file)) {
      retVal = 1;
    } else if (ferror(file)) {
      perror(filePath);
      retVal = -1;
    }
  }

  *fPos = ftell(file);
  fclose(file);

  return retVal;
}

int writeFile(const char *filePath, long *fPos, long broker) {
  FILE *file = fopen(filePath, "wb");
  if (file == NULL) {
    perror(filePath);
    return -1;
  }

  fseek(file, *fPos, SEEK_SET);

  int retVal = 0;
  long temp = 0;
  if ((temp = fwrite(decimal, 1, (STRING_LENGTH - broker) * CHAR_SIZE, file)) ==
      (STRING_LENGTH - broker) * CHAR_SIZE) {
    retVal = 0;
    printf("EXPLICIT NULL\n");
  } else if (ferror(file)) {
    perror(filePath);
    retVal = -1;
  }

  printf("WRITTEN BYTES: %ld\n", temp);

  *fPos = ftell(file);
  fclose(file);

  return retVal;
}

char *createNewFileName(const char *fileName, char *newFileName) {
  int i = 0;
  while (fileName[i] != '\0') {
    newFileName[i] = fileName[i];
    i++;
  }
  while (newFileName[i] != '.') {
    newFileName[i] = '\0';
    i--;
  }
  newFileName[i + 1] = 'b';
  newFileName[i + 2] = 'i';
  newFileName[i + 3] = 'n';
  newFileName[i + 4] = '\0';

  return newFileName;
}

#ifdef _WIN32

char *sanitizeInput(char *arg) {
  const int len = strlen(arg);
  if (len <= 2) {
    return arg;
  }
  if (arg[0] == '.' && arg[1] == '\\') {
    for (int i = 0; i < len - 2; i++) {
      arg[i] = arg[i + 2];
    }
    arg[len - 2] = '\0';
  }
  return arg;
}

#endif

int main(int argc, char *argv[]) {
  if (argc != 2) {
    printf("Usage: <filepath>\n");
    return 1;
  }

#ifdef _WIN32
  const char *filePath = sanitizeInput(argv[1]);
#elifdef __linux__
  const char *filePath = argv[1];
#endif

  char newFilePath[256] = {0};
  createNewFileName(filePath, newFilePath);

  int counter = 0;

  int status = 1;
  long fPosR = 0, fPosW = 0, difference = 0;
  while (status) {
    int retVal = readFile(filePath, &fPosR);
    printf("--%d---------------\n", counter);
    printf("READ: %d\n", retVal);
    switch (retVal) {
    case -1:
      return 1;
    case 0:
      break;
    case 1:
      status = 0;
      difference = fPosR - fPosW / CHAR_SIZE;
      difference = STRING_LENGTH - difference;
      break;
    }

    printf("DIFFERENCE: %ld\n", difference);

    printf("BINARY: %.10s\n", binary);
    binToDec(binary, STRING_LENGTH, decimal);
    //binToHex(binary, STRING_LENGTH, decimal);

    retVal = writeFile(newFilePath, &fPosW, difference);
    printf("WRITE: %d\n", retVal);
    switch (retVal) {
    case -1:
      return 1;
    case 0:
      break;
    }

    printf("OFFSET: %ld | %ld\n", fPosR, fPosW);

    memset(binary, 0, STRING_LENGTH);
    memset(decimal, 0, STRING_LENGTH * CHAR_SIZE);

    counter++;
  }

  return 0;
}
