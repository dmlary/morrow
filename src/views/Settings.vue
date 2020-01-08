<template>
  <div class="setting mx-5">
    <h1 class="subheading font-weight-thin">Settings</h1>
    <v-container>
      <v-card>
        <v-row wrap>
          <v-col sm="12" md="6">
            <v-switch
              class="pl-5"
              label="Dark Theme"
              v-model="$vuetify.theme.dark"
            />
          </v-col>
        </v-row>
      </v-card>
    </v-container>
  </div>
</template>

<script>
export default {
  data: () => ({}),
  computed: {},
  mounted() {}
};
</script>
