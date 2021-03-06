package NewLanguage.textGen;

/*Generated by MPS */

import jetbrains.mps.text.rt.TextGenDescriptorBase;
import jetbrains.mps.text.rt.TextGenContext;
import jetbrains.mps.text.impl.TextGenSupport;
import jetbrains.mps.lang.smodel.generator.smodelAdapter.SPropertyOperations;
import jetbrains.mps.lang.smodel.generator.smodelAdapter.SLinkOperations;
import org.jetbrains.mps.openapi.language.SReferenceLink;
import jetbrains.mps.smodel.adapter.structure.MetaAdapterFactory;
import org.jetbrains.mps.openapi.language.SProperty;

public class Listen_TextGen extends TextGenDescriptorBase {
  @Override
  public void generateText(final TextGenContext ctx) {
    final TextGenSupport tgs = new TextGenSupport(ctx);
    tgs.append("[");
    tgs.append(String.valueOf(SPropertyOperations.getInteger(SLinkOperations.getTarget(ctx.getPrimaryInput(), LINKS.server$qdBw), PROPS.id$q590)));
    tgs.append("]");
    tgs.append("?");
    tgs.newLine();
  }

  private static final class LINKS {
    /*package*/ static final SReferenceLink server$qdBw = MetaAdapterFactory.getReferenceLink(0xbccde9bf61a047d3L, 0xac545528183d161bL, 0xb487408a09f39c7L, 0xb487408a09f39c8L, "server");
  }

  private static final class PROPS {
    /*package*/ static final SProperty id$q590 = MetaAdapterFactory.getProperty(0xbccde9bf61a047d3L, 0xac545528183d161bL, 0xb487408a09f393bL, 0xb487408a09f393cL, "id");
  }
}
