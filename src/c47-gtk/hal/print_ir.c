// SPDX-License-Identifier: GPL-3.0-only
// SPDX-FileCopyrightText: Copyright The C47 Authors

#include "c47.h"
#include "c47-gtk.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

/*
*  Send printer output to emulated HP 82440B by Christoph Gieselink
*/

#include <glib.h>
#include <gio/gio.h>

#define UDPPORT 5025
#define UDPHOST "127.0.0.1"


//
//  Get print line delay
//
uint32_t getLineDelay(void) {
  return 0; // No delay on the simulator
}


//
//  Set print line delay
//
void setLineDelay(uint16_t delay) {
  return; // No delay on the simulator
}


//
// Send Byte to over IR
//
void sendByteIR(uint8_t c) {
#if defined(IR_PRINTING)
  GError         *error = NULL;
  GInetAddress   *udpAddress;
  GSocketAddress *udpSocketAddress;
  GSocket        *udpSocket;
  gssize size_sent;
  gchar buffer[8];

  buffer[0] = c;
  //set_IO_annunciator();

  udpAddress = g_inet_address_new_from_string(UDPHOST);
  guint16 udpPort = UDPPORT;
  g_assert(error == NULL);

  //Socket address used by the printer simulators (Christoph Giesselink HP82240B simulator or WP34S GTK printer simulator)
  udpSocketAddress = g_inet_socket_address_new(udpAddress, udpPort);
  if(udpSocketAddress == NULL){
    printf("Error UDP socket address\n");
    exit(1);
  }

  //Creates socket UDP IPV4
  udpSocket = g_socket_new(G_SOCKET_FAMILY_IPV4, G_SOCKET_TYPE_DATAGRAM, 17, &error);
  if(error != NULL) {
    printf("Error g_socket_new - domain: %d code: %d %s\n", error->domain, error->code, error->message);
    g_error_free(error);
    exit(1);
  }

  //Connect socket
  if(g_socket_connect(udpSocket, udpSocketAddress, NULL, &error) == FALSE) {
    printf("Error g_socket_connect - domain: %d code: %d %s\n", error->domain, error->code, error->message);
    g_error_free(error);
    exit(1);
  }

  //Send character to the socket
  size_sent = g_socket_send(udpSocket, buffer, 1, NULL, &error);
  if(error != NULL) {
    printf("Error g_socket_send - domain: %d code: %d %s size_sent %lld\n", error->domain, error->code, error->message, (long long)size_sent);
    g_error_free(error);
  }

  //Close the socket
  g_socket_close(udpSocket, NULL);
  if(error != NULL) {
    g_error_free(error);
  }

#endif //IR_PRINTING
}

void printer_advance_buf(int what) {
}

int printer_busy_for(int what) {
  return 0;
}

uint16_t printer_get_delay(void) {
  return 0;
}

uint16_t printer_set_delay(uint16_t val) {
  return 0;
}

/*
uint8_t *lcd_line_addr(int y) {
  return 0;
}
*/
