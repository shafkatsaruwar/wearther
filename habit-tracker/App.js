import { StatusBar } from "expo-status-bar";
import { StyleSheet, Text, View } from "react-native";

export default function App() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Steady</Text>
      <Text style={styles.subtitle}>Your calm habit tracker</Text>
      <StatusBar style="dark" />
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#E8F0EA",
    alignItems: "center",
    justifyContent: "center",
    padding: 24,
  },
  title: {
    fontSize: 36,
    fontWeight: "600",
    color: "#2F4A40",
    marginBottom: 8,
  },
  subtitle: {
    fontSize: 16,
    color: "#6F9486",
  },
});
