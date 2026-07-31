import Darwin
import FUMLiveEpisodeCore

do {
  let result = try LiveEpisodeFixture.run()
  let selection = result.state.model.selection?.selectedVariantID ?? "none"
  let transition = result.state.transition?.phase.rawValue ?? "none"
  print(
    "live_episode_fixture=passed events=\(result.events.count) "
      + "variants=\(result.state.model.variants.count) "
      + "selection=\(selection) transition=\(transition)"
  )
} catch {
  print("live_episode_fixture=failed error=\(error)")
  exit(1)
}
