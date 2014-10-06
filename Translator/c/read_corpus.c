#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
#include "libstemmer_c/libstemmer/libstemmer.h"

#define LINE_LENGTH 1024
#define WORD_LENGTH 64
#define OUTPUT_BATCH_SIZE   100000

int has_numerals(char *str) {
  while(*str)
  {
    if(isdigit(*str))
      return 1;
    str++;
  }
  return 0;
}

FILE * output(int batch_id) {
    char output_filepath[100];
    sprintf(output_filepath, "../resources/redis/en/%d.txt\0", batch_id);
    printf("%s\n", output_filepath);
    FILE * file = fopen(output_filepath, "w");
    return file;
}

int main() {
    // Stemmer
    char * language = "english";
    char * lang = "en";

    char * charenc = NULL;
    struct sb_stemmer * stemmer = sb_stemmer_new(language, charenc);;
    sb_symbol * b = (sb_symbol *) malloc(sizeof(sb_symbol));
    const sb_symbol * stemmed;

    // Input
    char* input_filepath = "../resources/corpus/europarl-v7.es-en.en";
    FILE * input_file = fopen(input_filepath, "r");
    char line[LINE_LENGTH];
    size_t length = 0;
    ssize_t read;
    char current;
    int i, j;
    char word_buffer[WORD_LENGTH];
    char * previous_word = NULL;
    int word_length = 0;

    // Output
    int batch_id = 1;
    FILE * output_file = output(batch_id);

    int line_counter = 0;
    while ((fgets(line, sizeof(line), input_file)) != NULL) {

        word_length = 0;
        for (i=0; i<LINE_LENGTH; i++) {
            if (line[i] == '\'' || line[i] == '\"' || line[i] == '-' || line[i] == '(' || line[i] == ')')
                continue;

            if (line[i] == ' ' && word_length == 0)
                continue;

            if (word_length > 0 && (line[i] == ' ' || line[i] == '.' || line[i] == ',' || line[i] == '!' || line[i] == '?' || line[i] == '\n')) {
                //printf("%.*s\n", word_length, word);
                sb_symbol * newb = (sb_symbol *) realloc(b, (word_length+1) * sizeof(sb_symbol));

                for (j=0; j<word_length; j++) {
                    newb[j] = tolower(word_buffer[j]);
                }
                newb[word_length] = '\0';

                if (!has_numerals(b)) {
                    stemmed = sb_stemmer_stem(stemmer, newb, word_length);

                    // Word frequency
                    fprintf(output_file, "INCR %s:1:%s\n", lang, newb);

                    if (strcmp(newb, stemmed) != 0) {
                        // Stemming versions frequency
                        fprintf(output_file, "HINCRBY %s:2:%s %s 1\n", lang, stemmed, newb);
                    }
                    // Sentence words
                    fprintf(output_file, "RPUSH %s:3:%d %s\n", lang, line_counter+1, newb);

                    // Word sentences
                    fprintf(output_file, "SADD %s:4:%s %d\n", lang, newb, line_counter+1);

                    if (previous_word != NULL) {
                        // Bigram frequency
                        fprintf(output_file, "HINCRBY %s:5:%s %s 1\n", lang, previous_word, newb);
                    }

                    previous_word = (char *) realloc(previous_word, (word_length+1)*sizeof(char));
                    strcpy(previous_word, newb);
                    //previous_word[word_length] = '\0';




                }


                word_length = 0;

                b = newb;
            }
            else {
                word_buffer[word_length] = line[i];
                word_length++;
            }

            if (line[i] == '\0') {
                break;
            }

        }
        previous_word = NULL;
        line_counter++;

        if (line_counter % OUTPUT_BATCH_SIZE == 0) {
            batch_id++;
            fclose(output_file);
            printf("Closed output file\n");
            output_file = output(batch_id);
        }
    }
    free(b);
    sb_stemmer_delete(stemmer);
    fclose(input_file);
    fclose(output_file);
}
